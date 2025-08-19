#!/usr/bin/env bash
set -euo pipefail

# Complete Clean Install Script
# This removes all Terraform state and starts fresh

echo "🧹 COMPLETE CLEAN INSTALL"
echo "========================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [[ ! -f "infra/envs/dev/main.tf" ]]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

echo "This script will:"
echo "1. Remove all local Terraform state files"
echo "2. Remove .terraform directories"
echo "3. Remove local terraform.tfvars"
echo "4. Clean up any cached data"
echo "5. Prepare for fresh GitHub Actions deployment"
echo ""

read -p "⚠️  Are you sure you want to continue? This will destroy ALL local Terraform state! (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Clean install cancelled"
    exit 0
fi

echo ""
print_info "Starting complete cleanup..."

# Step 1: Remove all Terraform state files
print_info "Removing Terraform state files..."
find . -name "*.tfstate*" -delete
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "tfplan" -delete
find . -name ".terraform.lock.hcl" -delete

# Step 2: Remove local terraform.tfvars (will be recreated by GitHub Actions)
print_info "Removing local terraform.tfvars..."
rm -f infra/envs/dev/terraform.tfvars

# Step 3: Clean up any other Terraform artifacts
print_info "Cleaning up other Terraform artifacts..."
find . -name "terraform.tfstate.backup" -delete
find . -name ".terraform.tfstate.lock.info" -delete

# Step 4: Verify cleanup
print_info "Verifying cleanup..."
if find . -name "*.tfstate*" | grep -q .; then
    print_warning "Some state files may still exist:"
    find . -name "*.tfstate*"
else
    print_success "All state files removed"
fi

if find . -name ".terraform" -type d | grep -q .; then
    print_warning "Some .terraform directories may still exist:"
    find . -name ".terraform" -type d
else
    print_success "All .terraform directories removed"
fi

echo ""
print_success "Complete cleanup finished!"
echo ""
echo "📝 Next steps:"
echo "1. All local Terraform state has been removed"
echo "2. GitHub Actions will create fresh terraform.tfvars from secrets"
echo "3. Trigger GitHub Actions workflow for fresh deployment"
echo ""
echo "🚀 To deploy:"
echo "   - Go to: https://github.com/sirschrockalot/gcp-project-setup/actions"
echo "   - Click 'Terraform Apply'"
echo "   - Click 'Run workflow'"
echo "   - Select environment 'dev'"
echo "   - Click 'Run workflow'"
echo ""
echo "✅ Fresh deployment will start with no state conflicts!"
