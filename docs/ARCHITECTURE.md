# Infrastructure Architecture

## Overview

This infrastructure provides a cost-optimized Google Cloud Platform setup for development environments, featuring:

- **GKE Cluster**: Kubernetes cluster for running Docker containers
- **VPC Networking**: Private network with Cloud NAT for internet access
- **IAM Security**: Service accounts with least-privilege access
- **CI/CD Ready**: GitHub Actions integration with OIDC authentication

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    GCP Project                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐               │
│  │   IAM Module   │    │  Project Module │               │
│  │                 │    │                 │               │
│  │ • GKE SA       │    │ • Project       │               │
│  │ • CI/CD SA     │    │ • APIs          │               │
│  │ • Workload ID  │    │ • Billing       │               │
│  └─────────────────┘    └─────────────────┘               │
│           │                       │                        │
│           └───────────────────────┼────────────────────────┘
│                                   │                        │
│  ┌─────────────────┐    ┌─────────────────┐               │
│  │ Network Module  │    │   GKE Module    │               │
│  │                 │    │                 │               │
│  │ • VPC          │    │ • Cluster       │               │
│  │ • Subnets      │    │ • Node Pools    │               │
│  │ • Firewall     │    │ • Autoscaling   │               │
│  │ • Cloud NAT    │    │ • Workload ID   │               │
│  └─────────────────┘    └─────────────────┘               │
│           │                       │                        │
│           └───────────────────────┼────────────────────────┘
│                                   │                        │
│  ┌─────────────────┐    ┌─────────────────┐               │
│  │  Artifact Reg  │    │  Cloud Storage  │               │
│  │                 │    │                 │               │
│  │ • Docker Repo  │    │ • Terraform     │               │
│  │ • IAM Access   │    │   State         │               │
│  └─────────────────┘    └─────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

## Cost Optimization Features

### GKE Configuration
- **Preemptible Nodes**: 60-80% cost savings vs regular instances
- **Autoscaling**: Scales from 1-3 nodes based on demand
- **Machine Types**: e2-standard-2 for optimal price/performance
- **Regional Cluster**: High availability with minimal cost increase

### Networking
- **Cloud NAT**: Single NAT gateway for all private instances
- **Private Nodes**: No public IP costs for worker nodes
- **Efficient Subnetting**: Optimized IP ranges for pods and services

### Storage
- **Standard Storage**: Cost-effective for development workloads
- **Lifecycle Policies**: Automatic cleanup of old objects
- **Regional Storage**: Reduced egress costs

## Security Features

### IAM & Access Control
- **Service Accounts**: Dedicated accounts for different services
- **Workload Identity**: OIDC-based authentication for CI/CD
- **Least Privilege**: Minimal required permissions for each service
- **Custom Roles**: Tailored permissions for GKE management

### Network Security
- **Private Subnets**: Worker nodes in private subnets
- **Firewall Rules**: Controlled access to services
- **Network Policies**: Pod-level network segmentation
- **Shielded Nodes**: Enhanced security for GKE nodes

### Data Protection
- **Secret Manager**: Secure storage for application secrets
- **Encryption**: Data encrypted at rest and in transit
- **Audit Logging**: Comprehensive logging for compliance

## Scalability Features

### Horizontal Scaling
- **Node Autoscaling**: Automatic node pool scaling
- **Pod Autoscaling**: HPA support for application scaling
- **Multi-Zone**: Regional cluster across 3 zones

### Vertical Scaling
- **Machine Types**: Easy to change instance sizes
- **Storage**: Flexible disk sizing and types
- **Memory**: Configurable memory allocation

## Monitoring & Observability

### Logging
- **Cloud Logging**: Centralized log collection
- **Structured Logs**: JSON-formatted logs for analysis
- **Log Retention**: Configurable retention policies

### Metrics
- **Cloud Monitoring**: Infrastructure and application metrics
- **Custom Metrics**: Support for application-specific metrics
- **Alerting**: Configurable alert policies

## CI/CD Integration

### GitHub Actions
- **OIDC Authentication**: Secure GCP access without keys
- **Automated Plans**: Terraform plan on pull requests
- **Automated Deployments**: Apply on merge to main
- **Artifact Management**: Docker image builds and pushes

### Workflow
1. **Plan Phase**: Validate changes and show impact
2. **Apply Phase**: Deploy approved changes
3. **Output Capture**: Store deployment results
4. **Notification**: Comment on PRs and commits

## Disaster Recovery

### State Management
- **Remote Backend**: GCS-based Terraform state
- **State Locking**: Prevents concurrent modifications
- **Versioning**: State file versioning for recovery

### Backup & Recovery
- **GKE Backups**: Automatic etcd backups
- **Storage Backups**: Configurable backup policies
- **Documentation**: Runbook for recovery procedures

## Compliance & Governance

### Resource Tagging
- **Environment Labels**: Clear environment identification
- **Owner Tracking**: Resource ownership tracking
- **Cost Center**: Cost allocation and tracking
- **Managed By**: Infrastructure management tracking

### Policy Enforcement
- **Terraform Validation**: Infrastructure as code validation
- **Security Scanning**: tfsec integration for security checks
- **Format Standards**: Consistent code formatting
- **Documentation**: Auto-generated documentation
