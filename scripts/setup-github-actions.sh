#!/usr/bin/env bash
set -euo pipefail

# Setup script for GitHub Actions with Workload Identity Federation
# This script sets up the necessary GCP resources for GitHub Actions to deploy infrastructure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if gcloud is installed and authenticated
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with gcloud. Please run: gcloud auth login"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Get user input
get_user_input() {
    print_status "Getting configuration details..."
    
    # Get current project
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    
    if [[ -z "$CURRENT_PROJECT" ]]; then
        print_error "No project is set. Please run: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
    
    read -p "Project ID [$CURRENT_PROJECT]: " PROJECT_ID
    PROJECT_ID=${PROJECT_ID:-$CURRENT_PROJECT}
    
    read -p "GitHub repository (format: owner/repo) [joelschrock/gcp-project-setup]: " GITHUB_REPO
    GITHUB_REPO=${GITHUB_REPO:-"joelschrock/gcp-project-setup"}
    
    read -p "Workload Identity Pool ID [github-actions-pool]: " POOL_ID
    POOL_ID=${POOL_ID:-"github-actions-pool"}
    
    read -p "Workload Identity Provider ID [github-actions-provider]: " PROVIDER_ID
    PROVIDER_ID=${PROVIDER_ID:-"github-actions-provider"}
    
    read -p "Service Account Name [github-actions-sa]: " SERVICE_ACCOUNT_NAME
    SERVICE_ACCOUNT_NAME=${SERVICE_ACCOUNT_NAME:-"github-actions-sa"}
    
    read -p "Terraform State Bucket Name [tfstate-presidentialdigs-dev]: " TF_STATE_BUCKET
    TF_STATE_BUCKET=${TF_STATE_BUCKET:-"tfstate-presidentialdigs-dev"}
    
    print_success "Configuration collected"
}

# Create Workload Identity Pool
create_workload_identity_pool() {
    print_status "Creating Workload Identity Pool..."
    
    if gcloud iam workload-identity-pools describe "$POOL_ID" --project="$PROJECT_ID" --location="global" &>/dev/null; then
        print_warning "Workload Identity Pool '$POOL_ID' already exists"
    else
        gcloud iam workload-identity-pools create "$POOL_ID" \
            --project="$PROJECT_ID" \
            --location="global" \
            --display-name="GitHub Actions Pool"
        print_success "Workload Identity Pool created"
    fi
}

# Create Workload Identity Provider
create_workload_identity_provider() {
    print_status "Creating Workload Identity Provider..."
    
    if gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" --project="$PROJECT_ID" --location="global" --workload-identity-pool="$POOL_ID" &>/dev/null; then
        print_warning "Workload Identity Provider '$PROVIDER_ID' already exists"
    else
        gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
            --project="$PROJECT_ID" \
            --location="global" \
            --workload-identity-pool="$POOL_ID" \
            --issuer-uri="https://token.actions.githubusercontent.com" \
            --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
            --attribute-condition="assertion.repository=='$GITHUB_REPO'"
        print_success "Workload Identity Provider created"
    fi
}

# Create Service Account
create_service_account() {
    print_status "Creating Service Account..."
    
    if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" --project="$PROJECT_ID" &>/dev/null; then
        print_warning "Service Account '$SERVICE_ACCOUNT_NAME' already exists"
    else
        gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
            --project="$PROJECT_ID" \
            --display-name="GitHub Actions Service Account"
        print_success "Service Account created"
    fi
}

# Grant roles to Service Account
grant_roles() {
    print_status "Granting roles to Service Account..."
    
    local roles=(
        "roles/editor"
        "roles/serviceusage.serviceUsageAdmin"
        "roles/resourcemanager.projectCreator"
        "roles/billing.user"
        "roles/storage.admin"
    )
    
    for role in "${roles[@]}"; do
        print_status "Granting $role..."
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
            --role="$role" \
            --quiet
    done
    
    print_success "Roles granted"
}

# Allow GitHub Actions to impersonate the service account
allow_impersonation() {
    print_status "Allowing GitHub Actions to impersonate Service Account..."
    
    local project_number=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
    local principal_set="principalSet://iam.googleapis.com/projects/$project_number/locations/global/workloadIdentityPools/$POOL_ID/attribute.repository/$GITHUB_REPO"
    
    gcloud iam service-accounts add-iam-policy-binding "$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --project="$PROJECT_ID" \
        --role="roles/iam.workloadIdentityUser" \
        --member="$principal_set"
    
    print_success "Impersonation allowed"
}

# Create Terraform state bucket
create_terraform_state_bucket() {
    print_status "Creating Terraform state bucket..."
    
    if gsutil ls -b "gs://$TF_STATE_BUCKET" &>/dev/null; then
        print_warning "Bucket 'gs://$TF_STATE_BUCKET' already exists"
    else
        gsutil mb -p "$PROJECT_ID" "gs://$TF_STATE_BUCKET"
        gsutil versioning set on "gs://$TF_STATE_BUCKET"
        gsutil uniformbucketlevelaccess set on "gs://$TF_STATE_BUCKET"
        print_success "Terraform state bucket created"
    fi
}

# Get the Workload Identity Provider resource name
get_workload_identity_provider() {
    WORKLOAD_IDENTITY_PROVIDER=$(gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
        --project="$PROJECT_ID" \
        --location="global" \
        --workload-identity-pool="$POOL_ID" \
        --format="value(name)")
}

# Display results
display_results() {
    print_success "Setup completed successfully!"
    echo ""
    echo "=== GitHub Secrets Configuration ==="
    echo ""
    echo "Add the following secrets to your GitHub repository:"
    echo "Settings → Secrets and variables → Actions"
    echo ""
    echo "| Secret Name | Value |"
    echo "|-------------|-------|"
    echo "| WORKLOAD_IDENTITY_PROVIDER | $WORKLOAD_IDENTITY_PROVIDER |"
    echo "| GCP_SA_EMAIL | $SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com |"
    echo "| TF_STATE_BUCKET | $TF_STATE_BUCKET |"
    echo "| TF_STATE_PREFIX | terraform/state |"
    echo ""
    echo "You'll also need to add:"
    echo "| ORG_ID | $(gcloud organizations list --format='value(name)' | head -1) |"
    echo "| BILLING_ACCOUNT | $(gcloud billing accounts list --format='value(ACCOUNT_ID)' | head -1) |"
    echo ""
    echo "=== Next Steps ==="
    echo "1. Add the secrets to your GitHub repository"
    echo "2. Create a test branch and make a change to trigger the workflow"
    echo "3. Check the Actions tab in your GitHub repository"
    echo ""
    echo "For detailed instructions, see: docs/GITHUB_ACTIONS_SETUP.md"
}

# Main execution
main() {
    echo "🚀 GitHub Actions Setup for GCP Infrastructure"
    echo "=============================================="
    echo ""
    
    check_prerequisites
    get_user_input
    
    echo ""
    echo "Configuration:"
    echo "- Project ID: $PROJECT_ID"
    echo "- GitHub Repo: $GITHUB_REPO"
    echo "- Pool ID: $POOL_ID"
    echo "- Provider ID: $PROVIDER_ID"
    echo "- Service Account: $SERVICE_ACCOUNT_NAME"
    echo "- State Bucket: $TF_STATE_BUCKET"
    echo ""
    
    read -p "Continue with this configuration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled"
        exit 0
    fi
    
    echo ""
    create_workload_identity_pool
    create_workload_identity_provider
    create_service_account
    grant_roles
    allow_impersonation
    create_terraform_state_bucket
    get_workload_identity_provider
    display_results
}

# Run main function
main "$@"
