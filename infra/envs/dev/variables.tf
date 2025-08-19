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

variable "region" {
  description = "The region to create resources in"
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "The zones to create resources in"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    env         = "dev"
    owner       = "joel.schrock"
    application = "presidentialdigs"
    cost_center = "cc-001"
    managed_by  = "terraform"
  }
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
  description = "List of subnets fully qualified subnet IDs"
  type        = list(string)
  default     = []
}

variable "shared_vpc_subnets_secondary_ranges" {
  description = "A map where the key is the subnetwork name and the value is a list of secondary ranges"
  type        = map(list(object({ range_name = string, ip_cidr_range = string })))
  default     = {}
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "vpc-main"
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    private_ip_google_access = bool
  }))
  default = [
    {
      name          = "subnet-main"
      ip_cidr_range = "10.10.0.0/24"
      region        = "us-central1"
      private_ip_google_access = true
    }
  ]
}

variable "secondary_ranges" {
  description = "Secondary IP ranges for GKE pods and services"
  type = map(list(object({
    range_name    = string
    ip_cidr_range = string
  })))
  default = {
    "subnet-main" = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.20.0.0/20"
      },
      {
        range_name    = "services"
        ip_cidr_range = "10.30.0.0/24"
      }
    ]
  }
}

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for private instances to access internet"
  type        = bool
  default     = true
}

variable "enable_cloud_router" {
  description = "Enable Cloud Router for Cloud NAT"
  type        = bool
  default     = true
}

variable "enable_firewall_rules" {
  description = "Enable default firewall rules"
  type        = bool
  default     = true
}

variable "allowed_ssh_networks" {
  description = "List of CIDR ranges allowed to SSH to instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Warning: This is open for development
}

variable "allowed_http_networks" {
  description = "List of CIDR ranges allowed to access HTTP/HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Warning: This is open for development
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

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "dev-cluster"
}

variable "enable_private_nodes" {
  description = "Enable private nodes (nodes without public IPs)"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint (master accessible only from VPC)"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The IP range for the master network"
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_network_policy" {
  description = "Enable network policy for GKE"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity"
  type        = bool
  default     = true
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded GKE nodes"
  type        = bool
  default     = true
}

variable "enable_legacy_abac" {
  description = "Enable legacy ABAC (not recommended for production)"
  type        = bool
  default     = false
}

variable "enable_kubernetes_dashboard" {
  description = "Enable Kubernetes Dashboard"
  type        = bool
  default     = false
}

variable "enable_cloud_logging" {
  description = "Enable Cloud Logging"
  type        = bool
  default     = true
}

variable "enable_cloud_monitoring" {
  description = "Enable Cloud Monitoring"
  type        = bool
  default     = true
}

variable "node_pools" {
  description = "List of node pools to create"
  type = list(object({
    name               = string
    machine_type       = string
    disk_size_gb       = number
    disk_type          = string
    initial_node_count = number
    min_count          = number
    max_count          = number
    max_surge          = number
    max_unavailable    = number
    preemptible        = bool
    spot               = bool
    labels             = map(string)
    taints             = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = [
    {
      name               = "default-pool"
      machine_type       = "e2-standard-2"  # Cost-optimized for dev
      disk_size_gb       = 50
      disk_type          = "pd-standard"
      initial_node_count = 1
      min_count          = 1
      max_count          = 3
      max_surge          = 1
      max_unavailable    = 0
      preemptible        = true  # Cost optimization for dev
      spot               = false
      labels = {
        pool = "default"
      }
      taints = []
    }
  ]
}

variable "maintenance_policy" {
  description = "Maintenance policy for the cluster"
  type = object({
    daily_maintenance_window = object({
      start_time = string
    })
  })
  default = {
    daily_maintenance_window = {
      start_time = "03:00"
    }
  }
}

variable "release_channel" {
  description = "Release channel for the cluster"
  type        = string
  default     = "regular"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = null
}


