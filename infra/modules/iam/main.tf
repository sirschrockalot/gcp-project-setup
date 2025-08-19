variable "project_id" {
  description = "The project ID to create IAM resources in"
  type        = string
}

variable "labels" {
  description = "Labels to apply to all IAM resources"
  type        = map(string)
  default     = {}
}

variable "enable_gke_service_account" {
  description = "Enable GKE service account"
  type        = bool
  default     = true
}

variable "enable_ci_service_account" {
  description = "Enable CI/CD service account for GitHub Actions"
  type        = bool
  default     = true
}

variable "enable_monitoring_service_account" {
  description = "Enable monitoring service account"
  type        = bool
  default     = false
}

variable "gke_service_account_name" {
  description = "Name for the GKE service account"
  type        = string
  default     = "gke-node-sa"
}

variable "ci_service_account_name" {
  description = "Name for the CI/CD service account"
  type        = string
  default     = "github-actions-sa"
}

variable "monitoring_service_account_name" {
  description = "Name for the monitoring service account"
  type        = string
  default     = "monitoring-sa"
}

variable "gke_service_account_roles" {
  description = "List of roles to assign to the GKE service account"
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader"
  ]
}

variable "ci_service_account_roles" {
  description = "List of roles to assign to the CI/CD service account"
  type        = list(string)
  default = [
    "roles/container.developer",
    "roles/artifactregistry.writer",
    "roles/storage.admin",
    "roles/secretmanager.secretAccessor",
    "roles/iam.serviceAccountUser"
  ]
}

variable "monitoring_service_account_roles" {
  description = "List of roles to assign to the monitoring service account"
  type        = list(string)
  default = [
    "roles/monitoring.admin",
    "roles/logging.admin",
    "roles/cloudtrace.user"
  ]
}

# GKE Service Account
resource "google_service_account" "gke" {
  count        = var.enable_gke_service_account ? 1 : 0
  account_id   = var.gke_service_account_name
  display_name = "GKE Node Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "gke_roles" {
  for_each = toset(var.gke_service_account_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.gke[0].email}"
}

# CI/CD Service Account for GitHub Actions
resource "google_service_account" "ci" {
  count        = var.enable_ci_service_account ? 1 : 0
  account_id   = var.ci_service_account_name
  display_name = "GitHub Actions CI/CD Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "ci_roles" {
  for_each = var.enable_ci_service_account ? toset(var.ci_service_account_roles) : toset([])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.ci[0].email}"
}

# Monitoring Service Account
resource "google_service_account" "monitoring" {
  count        = var.enable_monitoring_service_account ? 1 : 0
  account_id   = var.monitoring_service_account_name
  display_name = "Monitoring Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "monitoring_roles" {
  for_each = var.enable_monitoring_service_account ? toset(var.monitoring_service_account_roles) : toset([])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.monitoring[0].email}"
}

# Custom role for GKE cluster management
// Removed custom role to avoid invalid permission errors; built-in roles cover needs

# Workload Identity Pool for GitHub Actions OIDC
# Note: These resources are created manually via the setup script
# to avoid permission conflicts during initial deployment
# 
# The existing Workload Identity Federation setup allows GitHub Actions
# to authenticate using the configured service account

# resource "google_iam_workload_identity_pool" "github_actions" {
#   count                  = var.enable_ci_service_account ? 1 : 0
#   workload_identity_pool_id = "github-actions-pool"
#   project                = var.project_id
#   display_name           = "GitHub Actions Pool"
#   description            = "Identity pool for GitHub Actions OIDC"
# }

# resource "google_iam_workload_identity_pool_provider" "github_actions" {
#   count                           = var.enable_ci_service_account ? 1 : 0
#   workload_identity_pool_id       = google_iam_workload_identity_pool.github_actions[0].workload_identity_pool_id
#   workload_identity_pool_provider_id = "github-actions-provider"
#   project                         = var.project_id
#   display_name                    = "GitHub Actions Provider"
#   description                     = "OIDC provider for GitHub Actions"
#   
#   oidc {
#     issuer_uri        = "https://token.actions.githubusercontent.com"
#     allowed_audiences = ["https://token.actions.githubusercontent.com"]
#   }
#   
#   attribute_mapping = {
#     "google.subject"       = "assertion.sub"
#     "attribute.actor"      = "assertion.actor"
#     "attribute.repository" = "assertion.repository"
#     "attribute.ref"        = "assertion.ref"
#   }

#   attribute_condition = "attribute.repository == 'sirschrockalot/gcp-project-setup'"
# }

# resource "google_service_account_iam_binding" "workload_identity_binding" {
#   count              = var.enable_ci_service_account ? 1 : 0
#   service_account_id = google_service_account.ci[0].name
#   role               = "roles/iam.workloadIdentityUser"
#   members = [
#     "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions[0].workload_identity_pool_id}/attribute.repository/sirschrockalot/gcp-project-setup"
#   ]
# }

data "google_project" "current" {
  project_id = var.project_id
}

# Outputs
output "gke_service_account_email" {
  description = "Email of the GKE service account"
  value       = var.enable_gke_service_account ? google_service_account.gke[0].email : null
}

output "ci_service_account_email" {
  description = "Email of the CI/CD service account"
  value       = var.enable_ci_service_account ? google_service_account.ci[0].email : null
}

output "monitoring_service_account_email" {
  description = "Email of the monitoring service account"
  value       = var.enable_monitoring_service_account ? google_service_account.monitoring[0].email : null
}

# Workload Identity outputs removed - resources are managed manually
# output "workload_identity_pool_id" {
#   description = "ID of the workload identity pool (manually created)"
#   value       = "github-actions-pool"
# }

# output "workload_identity_provider_id" {
#   description = "ID of the workload identity provider (manually created)"
#   value       = "github-identity-provider"
# }
