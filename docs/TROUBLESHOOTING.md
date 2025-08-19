# Troubleshooting Guide

This guide covers common issues and their solutions when working with this GCP Terraform setup.

## Service Usage API Error

### Error Message
```
Error: Error when reading or editing Project Service presidentialdigs-dev/compute.googleapis.com: 
Request `List Project Services presidentialdigs-dev` returned error: 
Batch request and retried single request "List Project Services presidentialdigs-dev" both failed. 
Final error: Failed to list enabled services for project presidentialdigs-dev: 
googleapi: Error 403: Service Usage API has not been used in project 139931184497 before or it is disabled.
```

### Cause
The Service Usage API is required for Terraform to manage Google Cloud APIs, but it's not enabled in your project.

### Solution

#### Option 1: Use the Bootstrap Script (Recommended)
```bash
# Run the bootstrap script
make bootstrap-apis

# Or run directly
./scripts/enable_service_usage_api.sh presidentialdigs-dev
```

#### Option 2: Manual Enable via Console
1. Visit: https://console.developers.google.com/apis/api/serviceusage.googleapis.com/overview?project=YOUR_PROJECT_ID
2. Click "Enable"
3. Wait 2-3 minutes for propagation
4. Retry your Terraform command

#### Option 3: Manual Enable via gcloud
```bash
# Set your project
gcloud config set project presidentialdigs-dev

# Enable the Service Usage API
gcloud services enable serviceusage.googleapis.com

# Wait for propagation
sleep 30

# Verify it's enabled
gcloud services list --enabled --filter="name:serviceusage.googleapis.com"
```

### After Enabling Service Usage API
Once the Service Usage API is enabled, you can proceed with Terraform:

```bash
# Initialize Terraform
make init

# Plan your changes
make plan

# Apply your changes
make apply
```

## Common Authentication Issues

### Error: "Not authenticated with gcloud"
```bash
# Authenticate with gcloud
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Verify authentication
gcloud auth list
```

### Error: "Insufficient permissions"
Ensure your account has the necessary roles:
- `roles/serviceusage.serviceUsageAdmin` (to manage APIs)
- `roles/resourcemanager.projectCreator` (to create projects)
- `roles/billing.user` (to associate billing accounts)

## Terraform State Issues

### Error: "Backend configuration changed"
If you change the backend configuration:

```bash
# Reinitialize with new backend
terraform init -migrate-state

# Or force reinitialize
terraform init -reconfigure
```

### Error: "State file not found"
```bash
# Initialize Terraform
make init

# If using remote backend, ensure the bucket exists
make bootstrap
```

## Network and API Issues

### Error: "API not enabled"
If you encounter errors about specific APIs not being enabled:

1. The Service Usage API must be enabled first (see above)
2. Wait for API propagation (usually 2-3 minutes)
3. Retry the Terraform operation

### Error: "Quota exceeded"
Some APIs have quotas. Check your quotas in the Google Cloud Console:
- Go to APIs & Services > Quotas
- Look for the specific API that's failing
- Request a quota increase if needed

## Project Creation Issues

### Error: "Project ID already exists"
```bash
# Check if project exists
gcloud projects list --filter="projectId:YOUR_PROJECT_ID"

# If it exists, either:
# 1. Use a different project ID
# 2. Delete the existing project (if safe to do so)
gcloud projects delete YOUR_PROJECT_ID
```

### Error: "Billing account not found"
```bash
# List available billing accounts
gcloud billing accounts list

# Set the billing account
gcloud config set billing/YOUR_BILLING_ACCOUNT_ID
```

## Module-Specific Issues

### Network Module Errors
- Ensure the project exists before creating networks
- Check that the region exists and is available
- Verify CIDR ranges don't conflict

### GKE Module Errors
- Ensure the Compute Engine API is enabled
- Check that the Kubernetes Engine API is enabled
- Verify the service account has necessary permissions

### IAM Module Errors
- Ensure the IAM API is enabled
- Check that the service account doesn't already exist
- Verify the roles being assigned exist

## Debugging Commands

### Check API Status
```bash
# List all enabled APIs
gcloud services list --enabled

# Check specific API
gcloud services list --enabled --filter="name:compute.googleapis.com"
```

### Check Project Status
```bash
# Get project details
gcloud projects describe YOUR_PROJECT_ID

# List projects
gcloud projects list
```

### Check Terraform State
```bash
# Show current state
terraform show

# List resources in state
terraform state list

# Check specific resource
terraform state show module.project.google_project.main
```

### Enable Debug Logging
```bash
# Set Terraform log level
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run Terraform commands
make plan
```

## Getting Help

1. Check the logs: `tail -f terraform.log`
2. Review the [Architecture Documentation](ARCHITECTURE.md)
3. Check the [Onboarding Guide](ONBOARDING.md)
4. Review Terraform documentation for specific resources
5. Check Google Cloud documentation for API-specific issues

## Prevention Tips

1. **Always enable Service Usage API first** before running Terraform
2. **Use the bootstrap scripts** provided in this repository
3. **Test in a non-production environment** first
4. **Review the plan output** before applying changes
5. **Keep your gcloud CLI updated**: `gcloud components update`
6. **Use consistent naming conventions** as defined in the project
