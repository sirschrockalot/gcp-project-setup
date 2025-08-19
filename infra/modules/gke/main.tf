variable "project_id" {
  description = "The project ID to create the GKE cluster in"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "dev-cluster"
}

variable "region" {
  description = "The region to create the cluster in"
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "The zones to create the cluster in (for regional clusters, use 3 zones)"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "network" {
  description = "The VPC network to use"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to use"
  type        = string
}

variable "ip_range_pods" {
  description = "The secondary IP range for pods"
  type        = string
  default     = "10.20.0.0/20"
}

variable "ip_range_services" {
  description = "The secondary IP range for services"
  type        = string
  default     = "10.30.0.0/24"
}

variable "master_authorized_networks" {
  description = "List of CIDR ranges authorized to access the master"
  type        = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  ]
}

variable "labels" {
  description = "Labels to apply to all GKE resources"
  type        = map(string)
  default     = {}
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

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  project  = var.project_id
  location = var.region
  network  = var.network
  subnetwork = var.subnetwork

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Networking
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = var.master_authorized_networks
    content {
      cidr_blocks {
        cidr_block   = master_authorized_networks_config.value.cidr_block
        display_name = master_authorized_networks_config.value.display_name
      }
    }
  }

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Network policy
  network_policy {
    enabled = var.enable_network_policy
    provider = "CALICO"
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Shielded nodes
  enable_shielded_nodes = var.enable_shielded_nodes

  # Legacy ABAC
  enable_legacy_abac = var.enable_legacy_abac



  # Logging and Monitoring
  logging_config {
    enable_components = var.enable_cloud_logging ? ["SYSTEM_COMPONENTS", "WORKLOADS"] : []
  }

  monitoring_config {
    enable_components = var.enable_cloud_monitoring ? ["SYSTEM_COMPONENTS"] : []
  }

  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_policy.daily_maintenance_window.start_time
    }
  }

  # Release channel
  release_channel {
    channel = var.release_channel
  }

  # Version
  min_master_version = var.kubernetes_version

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

# Node Pools
resource "google_container_node_pool" "pools" {
  for_each = { for pool in var.node_pools : pool.name => pool }
  
  name       = each.value.name
  project    = var.project_id
  location   = var.region
  cluster    = google_container_cluster.primary.name
  version    = google_container_cluster.primary.master_version

  initial_node_count = each.value.initial_node_count

  autoscaling {
    min_node_count = each.value.min_count
    max_node_count = each.value.max_count
  }

  upgrade_settings {
    max_surge       = each.value.max_surge
    max_unavailable = each.value.max_unavailable
  }

  node_config {
    machine_type    = each.value.machine_type
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type
    preemptible     = each.value.preemptible
    spot            = each.value.spot

    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Labels
    labels = merge(var.labels, each.value.labels)

    # Taints
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded nodes
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }



  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

# Outputs
output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}



output "node_pool_names" {
  description = "List of node pool names"
  value       = [for pool in google_container_node_pool.pools : pool.name]
}

output "node_pool_versions" {
  description = "Map of node pool names to versions"
  value       = { for k, v in google_container_node_pool.pools : k => v.version }
}

output "workload_identity_pool" {
  description = "The workload identity pool"
  value       = google_container_cluster.primary.workload_identity_config[0].workload_pool
}
