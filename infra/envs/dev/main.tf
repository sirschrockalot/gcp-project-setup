# Project Factory Module
module "project" {
  source = "../../modules/project"
  
  org_id          = var.org_id
  billing_account = var.billing_account
  project_id      = var.project_id
  project_name    = var.project_name
  labels          = var.labels
  
  enable_shared_vpc_host = var.enable_shared_vpc_host
  enable_shared_vpc_service = var.enable_shared_vpc_service
  shared_vpc = var.shared_vpc
  shared_vpc_subnets = var.shared_vpc_subnets
  shared_vpc_subnets_secondary_ranges = var.shared_vpc_subnets_secondary_ranges
}

# Network Module
module "network" {
  source = "../../modules/network"
  
  project_id = module.project.project_id
  network_name = var.network_name
  subnets = var.subnets
  secondary_ranges = var.secondary_ranges
  labels = var.labels
  
  enable_cloud_nat = var.enable_cloud_nat
  enable_cloud_router = var.enable_cloud_router
  enable_firewall_rules = var.enable_firewall_rules
  allowed_ssh_networks = var.allowed_ssh_networks
  allowed_http_networks = var.allowed_http_networks
  
  depends_on = [module.project]
}

# IAM Module
module "iam" {
  source = "../../modules/iam"
  
  project_id = module.project.project_id
  labels = var.labels
  
  enable_gke_service_account = var.enable_gke_service_account
  enable_ci_service_account = var.enable_ci_service_account
  enable_monitoring_service_account = var.enable_monitoring_service_account
  
  gke_service_account_name = var.gke_service_account_name
  ci_service_account_name = var.ci_service_account_name
  monitoring_service_account_name = var.monitoring_service_account_name
  
  gke_service_account_roles = var.gke_service_account_roles
  ci_service_account_roles = var.ci_service_account_roles
  monitoring_service_account_roles = var.monitoring_service_account_roles
  
  depends_on = [module.project]
}

# GKE Module
module "gke" {
  source = "../../modules/gke"
  
  project_id = module.project.project_id
  cluster_name = var.cluster_name
  region = var.region
  zones = var.zones
  
  network = module.network.network_self_link
  subnetwork = module.network.subnet_self_links["subnet-main"]
  

  
  labels = var.labels
  
  enable_private_nodes = var.enable_private_nodes
  enable_private_endpoint = var.enable_private_endpoint
  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  
  enable_network_policy = var.enable_network_policy
  enable_workload_identity = var.enable_workload_identity
  enable_shielded_nodes = var.enable_shielded_nodes
  enable_legacy_abac = var.enable_legacy_abac
  
  enable_kubernetes_dashboard = var.enable_kubernetes_dashboard
  enable_cloud_logging = var.enable_cloud_logging
  enable_cloud_monitoring = var.enable_cloud_monitoring
  
  node_pools = var.node_pools
  maintenance_policy = var.maintenance_policy
  release_channel = var.release_channel
  kubernetes_version = var.kubernetes_version
  
  depends_on = [
    module.project,
    module.network,
    module.iam
  ]
}



# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = "docker-repo"
  description   = "Docker repository for Presidential Digs"
  format        = "DOCKER"
  
  labels = var.labels
  
  depends_on = [module.project]
}



resource "google_artifact_registry_repository_iam_member" "docker_writer" {
  location = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${module.iam.ci_service_account_email}"
}



# Secret Manager for application secrets
resource "google_secret_manager_secret" "app_secrets" {
  secret_id = "app-secrets"
  
  labels = var.labels
  
  replication {
    auto {}
  }
  
  depends_on = [module.project]
}

# IAM for Secret Manager
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = google_secret_manager_secret.app_secrets.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.iam.gke_service_account_email}"
}



# Cloud Build trigger for CI/CD (optional)
resource "google_cloudbuild_trigger" "build_trigger" {
  name        = "presidentialdigs-build"
  description = "Build trigger for Presidential Digs application"
  
  github {
    owner = "joelschrock"
    name  = "gcp-project-setup"
    push {
      branch = "main"
    }
  }
  
  filename = "cloudbuild.yaml"
  
  depends_on = [module.project]
}
