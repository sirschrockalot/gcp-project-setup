# GitHub Actions Setup Guide

This guide will help you set up GitHub Actions to deploy your GCP infrastructure using Workload Identity Federation for secure authentication.

## Prerequisites

1. **GCP Project**: You need a GCP project with the following APIs enabled:
   - Service Usage API
   - IAM API
   - Cloud Resource Manager API

2. **GCP Permissions**: Your account needs the following roles:
   - `roles/iam.workloadIdentityPoolAdmin`
   - `roles/iam.serviceAccountAdmin`
   - `roles/resourcemanager.projectIamAdmin`

3. **GitHub Repository**: Your code should be in a GitHub repository

## Step 1: Get GCP Information

First, let's get the required GCP information:

```bash
# Get your organization ID
gcloud organizations list

# Get your billing account ID
gcloud billing accounts list

# Get your project ID
gcloud config get-value project
```

## Step 2: Create Workload Identity Federation

Run the following commands to set up Workload Identity Federation:

```bash
# Set your variables
PROJECT_ID="presidentialdigs-dev"
GITHUB_REPO="joelschrock/gcp-project-setup"  # Replace with your repo
POOL_ID="github-actions-pool"
PROVIDER_ID="github-actions-provider"
SERVICE_ACCOUNT_NAME="github-actions-sa"

# Create Workload Identity Pool
gcloud iam workload-identity-pools create $POOL_ID \
  --project=$PROJECT_ID \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_ID \
  --project=$PROJECT_ID \
  --location="global" \
  --workload-identity-pool=$POOL_ID \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='$GITHUB_REPO'"

# Create Service Account
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --project=$PROJECT_ID \
  --display-name="GitHub Actions Service Account"

# Grant necessary roles to the service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.projectCreator"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/billing.user"

# Allow GitHub Actions to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com \
  --project=$PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')/locations/global/workloadIdentityPools/$POOL_ID/attribute.repository/$GITHUB_REPO"

# Get the Workload Identity Provider resource name
WORKLOAD_IDENTITY_PROVIDER=$(gcloud iam workload-identity-pools providers describe $PROVIDER_ID \
  --project=$PROJECT_ID \
  --location="global" \
  --workload-identity-pool=$POOL_ID \
  --format="value(name)")

echo "Workload Identity Provider: $WORKLOAD_IDENTITY_PROVIDER"
echo "Service Account Email: $SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"
```

## Step 3: Create GCS Bucket for Terraform State

```bash
# Create the Terraform state bucket
gsutil mb -p $PROJECT_ID gs://tfstate-presidentialdigs-dev

# Enable versioning for the bucket
gsutil versioning set on gs://tfstate-presidentialdigs-dev

# Set uniform bucket-level access
gsutil uniformbucketlevelaccess set on gs://tfstate-presidentialdigs-dev
```

## Step 4: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add the following secrets:

### Required Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `ORG_ID` | Your GCP organization ID | `123456789012` |
| `BILLING_ACCOUNT` | Your GCP billing account ID | `ABCD-12EF-3456` |
| `WORKLOAD_IDENTITY_PROVIDER` | Workload Identity Provider resource name | `projects/139931184497/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider` |
| `GCP_SA_EMAIL` | Service account email | `github-actions-sa@presidentialdigs-dev.iam.gserviceaccount.com` |
| `TF_STATE_BUCKET` | Terraform state bucket name | `tfstate-presidentialdigs-dev` |
| `TF_STATE_PREFIX` | Terraform state prefix | `terraform/state` |

### How to Get These Values

```bash
# Get the Workload Identity Provider (from Step 2)
echo $WORKLOAD_IDENTITY_PROVIDER

# Get the Service Account Email
echo "$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"

# Get Organization ID
gcloud organizations list --format="value(name)"

# Get Billing Account ID
gcloud billing accounts list --format="value(ACCOUNT_ID)"
```

## Step 5: Test the Setup

1. **Create a test branch:**
   ```bash
   git checkout -b test-github-actions
   ```

2. **Make a small change to trigger the workflow:**
   ```bash
   # Edit a file in the infra directory
   echo "# Test comment" >> infra/envs/dev/main.tf
   git add infra/envs/dev/main.tf
   git commit -m "test: trigger GitHub Actions workflow"
   git push origin test-github-actions
   ```

3. **Create a Pull Request** to the main branch

4. **Check the workflow** in the Actions tab of your GitHub repository

## Step 6: Deploy Infrastructure

Once the setup is working:

1. **Merge your PR** to trigger the apply workflow
2. **Or manually trigger** the apply workflow:
   - Go to Actions → Terraform Apply
   - Click "Run workflow"
   - Select the environment (dev)

## Troubleshooting

### Common Issues

1. **"Permission denied" errors:**
   - Ensure the service account has the necessary roles
   - Check that Workload Identity Federation is properly configured

2. **"Backend configuration changed" errors:**
   - The workflow handles this automatically with `terraform init`

3. **"API not enabled" errors:**
   - The Service Usage API should be enabled in your project
   - The workflow will enable other APIs as needed

### Debug Commands

```bash
# Check if the service account exists
gcloud iam service-accounts list --project=$PROJECT_ID

# Check Workload Identity Pool
gcloud iam workload-identity-pools list --project=$PROJECT_ID

# Check Workload Identity Provider
gcloud iam workload-identity-pools providers list \
  --project=$PROJECT_ID \
  --location="global" \
  --workload-identity-pool=$POOL_ID

# Test service account permissions
gcloud auth activate-service-account --key-file=/path/to/key.json
gcloud projects list
```

## Security Best Practices

1. **Principle of Least Privilege**: Only grant the minimum necessary roles
2. **Repository Restrictions**: The Workload Identity Provider is restricted to your specific repository
3. **Branch Protection**: Use branch protection rules to require PR reviews
4. **Environment Protection**: Use GitHub Environments for production deployments
5. **Audit Logging**: Monitor Cloud Audit Logs for service account usage

## Next Steps

1. **Set up branch protection rules** for the main branch
2. **Configure environments** for staging and production
3. **Set up monitoring** and alerting for infrastructure changes
4. **Document your infrastructure** using the generated outputs

## References

- [Workload Identity Federation Documentation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions for Terraform](https://learn.hashicorp.com/tutorials/terraform/github-actions)
- [GCP IAM Best Practices](https://cloud.google.com/iam/docs/best-practices)
