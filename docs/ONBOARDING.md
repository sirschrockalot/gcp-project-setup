# Onboarding Guide

## Prerequisites

1. **Google Cloud SDK**: Install and authenticate with `gcloud auth login`
2. **Terraform**: Install Terraform >= 1.6.0
3. **Access**: Ensure you have access to the GCP organization and billing account

## Initial Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd gcp-project-setup
```

### 2. Configure Environment Variables
Copy the example terraform.tfvars file and update with your values:
```bash
cd infra/envs/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your org_id and billing_account
```

### 3. Bootstrap Backend (First Time Only)
```bash
# Create the GCS bucket for Terraform state
./scripts/bootstrap_backend.sh <project-id> <bucket-name>
```

### 4. Initialize Terraform
```bash
terraform init
```

### 5. Plan and Apply
```bash
terraform plan
terraform apply
```

## Development Workflow

1. **Make Changes**: Edit Terraform files in `infra/`
2. **Run Quality Checks**: `./scripts/lint.sh`
3. **Plan Changes**: `terraform plan`
4. **Apply Changes**: `terraform apply`

## Cost Optimization

- **Preemptible Nodes**: GKE uses preemptible nodes for cost savings
- **Autoscaling**: Node pools scale from 1-3 nodes based on demand
- **Machine Types**: Uses e2-standard-2 for cost efficiency
- **Monitoring**: Enable Cloud Billing alerts to track costs

## Security Notes

⚠️ **Development Environment**: This setup has open firewall rules for development. Restrict access for production use.

## Getting Help

- Check the [Architecture Documentation](ARCHITECTURE.md)
- Review the [Runbook](RUNBOOK.md)
- Contact the platform team
