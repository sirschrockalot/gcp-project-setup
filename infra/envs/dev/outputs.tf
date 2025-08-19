# Project outputs
output "project_id" {
  description = "The project ID"
  value       = module.project.project_id
}

output "project_number" {
  description = "The project number"
  value       = module.project.project_number
}

output "project_name" {
  description = "The project name"
  value       = module.project.project_name
}

# Network outputs
output "network_id" {
  description = "The ID of the VPC network"
  value       = module.network.network_id
}

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = module.network.network_self_link
}

output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value       = module.network.subnet_ids
}

output "subnet_self_links" {
  description = "Map of subnet names to subnet self-links"
  value       = module.network.subnet_self_links
}

output "router_id" {
  description = "The ID of the Cloud Router"
  value       = module.network.router_id
}

output "nat_id" {
  description = "The ID of the Cloud NAT"
  value       = module.network.nat_id
}

# IAM outputs
output "gke_service_account_email" {
  description = "Email of the GKE service account"
  value       = module.iam.gke_service_account_email
}

output "ci_service_account_email" {
  description = "Email of the CI/CD service account"
  value       = module.iam.ci_service_account_email
}

output "monitoring_service_account_email" {
  description = "Email of the monitoring service account"
  value       = module.iam.monitoring_service_account_email
}

output "workload_identity_pool_id" {
  description = "ID of the workload identity pool"
  value       = module.iam.workload_identity_pool_id
}

output "workload_identity_provider_id" {
  description = "ID of the workload identity provider"
  value       = module.iam.workload_identity_provider_id
}

# GKE outputs
output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = module.gke.cluster_id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = module.gke.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}



output "node_pool_names" {
  description = "List of node pool names"
  value       = module.gke.node_pool_names
}

output "node_pool_versions" {
  description = "Map of node pool names to versions"
  value       = module.gke.node_pool_versions
}

output "workload_identity_pool" {
  description = "The workload identity pool"
  value       = module.gke.workload_identity_pool
}

# Artifact Registry outputs
output "docker_repository_id" {
  description = "The ID of the Docker repository"
  value       = google_artifact_registry_repository.docker.repository_id
}

output "docker_repository_name" {
  description = "The name of the Docker repository"
  value       = google_artifact_registry_repository.docker.name
}

output "docker_repository_location" {
  description = "The location of the Docker repository"
  value       = google_artifact_registry_repository.docker.location
}



# Secret Manager outputs
output "app_secrets_id" {
  description = "The ID of the app secrets"
  value       = google_secret_manager_secret.app_secrets.secret_id
}

# Cloud Build outputs
output "build_trigger_id" {
  description = "The ID of the build trigger (null if disabled)"
  value       = length(google_cloudbuild_trigger.build_trigger) > 0 ? google_cloudbuild_trigger.build_trigger[0].id : null
}

# Connection information
output "gke_connection_command" {
  description = "Command to connect to the GKE cluster"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${module.project.project_id}"
}

output "docker_push_command" {
  description = "Command to push Docker images to Artifact Registry"
  value       = "docker tag <image> ${var.region}-docker.pkg.dev/${module.project.project_id}/docker-repo/<image> && docker push ${var.region}-docker.pkg.dev/${module.project.project_id}/docker-repo/<image>"
}

output "cost_optimization_tips" {
  description = "Tips for cost optimization in development environment"
  value = [
    "Use preemptible nodes for cost savings (already configured)",
    "Set up node autoscaling with appropriate min/max counts",
    "Use e2-standard-2 machine types for cost efficiency",
    "Enable Cloud NAT for private instances to access internet",
    "Use regional clusters for high availability with minimal cost increase",
    "Monitor costs with Cloud Billing alerts",
    "Consider using spot instances for additional cost savings in non-critical workloads"
  ]
}
