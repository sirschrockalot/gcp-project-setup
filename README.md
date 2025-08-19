# GCP Project Setup - Presidential Digs Google Project

A production-ready, cost-optimized Google Cloud Platform infrastructure setup using Terraform, designed for development environments with GKE, networking, and IAM.

## 🚀 Features

- **GKE Cluster**: Cost-optimized Kubernetes cluster with preemptible nodes
- **VPC Networking**: Private network with Cloud NAT and firewall rules
- **IAM Security**: Service accounts with least-privilege access
- **CI/CD Ready**: GitHub Actions with OIDC authentication
- **Cost Optimized**: Preemptible nodes, autoscaling, efficient machine types
- **Production Ready**: Security best practices, monitoring, and compliance

## 🏗️ Architecture

This infrastructure provides:
- **Project Factory**: Automated project creation with APIs and billing
- **Network Module**: VPC, subnets, Cloud NAT, and firewall rules
- **IAM Module**: Service accounts, custom roles, and Workload Identity
- **GKE Module**: Regional cluster with autoscaling and cost optimization
- **Artifact Registry**: Docker image storage and management
- **Secret Manager**: Secure application secret storage

## 📋 Prerequisites

- Google Cloud SDK (`gcloud`)
- Terraform >= 1.6.0
- Access to GCP organization and billing account
- Python 3.7+ (for pre-commit hooks)

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd gcp-project-setup
make install
```

### 2. Configure Environment
```bash
cd infra/envs/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your org_id and billing_account
```

### 3. Bootstrap Backend
```bash
make bootstrap
# Follow prompts to enter project ID and bucket name
```

### 4. Deploy Infrastructure
```bash
make init
make plan
make apply
```

## 💰 Cost Optimization

This setup is designed for cost-effective development:

- **Preemptible Nodes**: 60-80% cost savings
- **Autoscaling**: Scales from 1-3 nodes based on demand
- **Efficient Machine Types**: e2-standard-2 for optimal price/performance
- **Regional Cluster**: High availability with minimal cost increase
- **Cloud NAT**: Single NAT gateway for all private instances

## 🔒 Security Features

- **Private Nodes**: Worker nodes in private subnets
- **Workload Identity**: OIDC-based authentication for CI/CD
- **Network Policies**: Pod-level network segmentation
- **Shielded Nodes**: Enhanced security for GKE nodes
- **Secret Manager**: Secure storage for application secrets

## 🛠️ Development Workflow

1. **Make Changes**: Edit Terraform files in `infra/`
2. **Quality Checks**: `make lint`
3. **Plan Changes**: `make plan`
4. **Apply Changes**: `make apply`

## 📚 Documentation

- [Onboarding Guide](docs/ONBOARDING.md) - Get started quickly
- [Architecture Guide](docs/ARCHITECTURE.md) - Understand the design
- [Runbook](docs/RUNBOOK.md) - Operational procedures

## 🔧 Available Commands

```bash
make help          # Show all available commands
make install       # Install development dependencies
make lint          # Run quality checks
make plan          # Run Terraform plan
make apply         # Run Terraform apply
make destroy       # Destroy infrastructure (use with caution)
make docs          # Generate documentation
make bootstrap     # Bootstrap GCS backend bucket
```

## 🚨 Important Notes

⚠️ **Development Environment**: This setup has open firewall rules for development. Restrict access for production use.

⚠️ **Cost Monitoring**: Enable Cloud Billing alerts to track costs.

⚠️ **Security**: Review and restrict firewall rules before production use.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run quality checks: `make lint`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- Check the [documentation](docs/)
- Review [GitHub Issues](../../issues)
- Contact the platform team

---

**Built with ❤️ for cost-effective, secure, and scalable cloud infrastructure**
