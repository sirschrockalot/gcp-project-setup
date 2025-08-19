variable "org_id" {
  description = "The numeric ID of the organization"
  type        = string
}

variable "billing_account" {
  description = "The ID of the billing account to associate with the project"
  type        = string
}

variable "project_id" {
  description = "The project ID to create"
  type        = string
}

variable "project_name" {
  description = "The display name of the project"
  type        = string
  default     = null
}

variable "apis" {
  description = "List of APIs to enable on the project"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "iam.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "networkmanagement.googleapis.com",
    "dns.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

variable "labels" {
  description = "Labels to apply to the project"
  type        = map(string)
  default     = {}
}

variable "enable_shared_vpc_host" {
  description = "Enable shared VPC host project"
  type        = bool
  default     = false
}

variable "enable_shared_vpc_service" {
  description = "Enable shared VPC service project"
  type        = bool
  default     = false
}

variable "shared_vpc" {
  description = "The ID of the host project that contains the shared VPC"
  type        = string
  default     = null
}

variable "shared_vpc_subnets" {
  description = "List of subnets fully qualified subnet IDs (ie. projects/$project_id/regions/$region/subnetworks/$subnet_id)"
  type        = list(string)
  default     = []
}

variable "shared_vpc_subnets_secondary_ranges" {
  description = "A map where the key is the subnetwork name and the value is a list of secondary ranges"
  type        = map(list(object({ range_name = string, ip_cidr_range = string })))
  default     = {}
}

resource "google_project" "main" {
  name            = var.project_name != null ? var.project_name : var.project_id
  project_id      = var.project_id
  org_id          = var.org_id
  billing_account = var.billing_account
  auto_create_network = false
  labels          = var.labels

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service" "enabled_apis" {
  for_each = toset(var.apis)
  project  = google_project.main.project_id
  service  = each.value

  disable_dependent_services = true
  disable_on_destroy         = false
}



# Shared VPC configuration
resource "google_compute_shared_vpc_host_project" "shared_vpc_host" {
  count   = var.enable_shared_vpc_host ? 1 : 0
  project = google_project.main.project_id
}

resource "google_compute_shared_vpc_service_project" "shared_vpc_service" {
  count   = var.enable_shared_vpc_service ? 1 : 0
  host_project = var.shared_vpc
  service_project = google_project.main.project_id
}

output "project_id" {
  description = "The project ID"
  value       = google_project.main.project_id
}

output "project_number" {
  description = "The project number"
  value       = google_project.main.number
}

output "project_name" {
  description = "The project name"
  value       = google_project.main.name
}
