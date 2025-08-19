variable "project_id" {
  description = "The project ID to create the network in"
  type        = string
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

variable "labels" {
  description = "Labels to apply to all network resources"
  type        = map(string)
  default     = {}
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

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"

  lifecycle {
    prevent_destroy = true
  }
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each                 = { for s in var.subnets : s.name => s }
  name                     = each.value.name
  project                  = var.project_id
  ip_cidr_range            = each.value.ip_cidr_range
  region                   = each.value.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = lookup(var.secondary_ranges, each.value.name, [])
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "router" {
  count   = var.enable_cloud_router ? 1 : 0
  name    = "router-${var.network_name}"
  project = var.project_id
  region  = var.subnets[0].region
  network = google_compute_network.vpc.id
}

# Cloud NAT for private instances to access internet
resource "google_compute_router_nat" "nat" {
  count                              = var.enable_cloud_nat ? 1 : 0
  name                               = "nat-${var.network_name}"
  project                            = var.project_id
  router                             = google_compute_router.router[0].name
  region                             = google_compute_router.router[0].region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_internal" {
  count   = var.enable_firewall_rules ? 1 : 0
  name    = "allow-internal-${var.network_name}"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [
    for subnet in var.subnets : subnet.ip_cidr_range
  ]
}

resource "google_compute_firewall" "allow_ssh" {
  count   = var.enable_firewall_rules ? 1 : 0
  name    = "allow-ssh-${var.network_name}"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_networks
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_http" {
  count   = var.enable_firewall_rules ? 1 : 0
  name    = "allow-http-${var.network_name}"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = var.allowed_http_networks
  target_tags   = ["http-server", "https-server"]
}

resource "google_compute_firewall" "allow_health_check" {
  count   = var.enable_firewall_rules ? 1 : 0
  name    = "allow-health-check-${var.network_name}"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]  # Google health check ranges
  target_tags   = ["health-check"]
}

# Outputs
output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.id }
}

output "subnet_self_links" {
  description = "Map of subnet names to subnet self-links"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.self_link }
}

output "router_id" {
  description = "The ID of the Cloud Router"
  value       = var.enable_cloud_router ? google_compute_router.router[0].id : null
}

output "nat_id" {
  description = "The ID of the Cloud NAT"
  value       = var.enable_cloud_nat ? google_compute_router_nat.nat[0].id : null
}
