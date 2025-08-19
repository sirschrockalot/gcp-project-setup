.PHONY: help install lint plan apply destroy clean docs

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install development dependencies
	@echo "Installing development dependencies..."
	pip install pre-commit
	pre-commit install

lint: ## Run all quality checks
	@echo "Running quality checks..."
	./scripts/lint.sh

plan: ## Run Terraform plan
	@echo "Running Terraform plan..."
	cd infra/envs/dev && terraform plan

apply: ## Run Terraform apply
	@echo "Running Terraform apply..."
	cd infra/envs/dev && terraform apply

destroy: ## Destroy infrastructure (use with caution)
	@echo "⚠️  Destroying infrastructure..."
	cd infra/envs/dev && terraform destroy

clean: ## Clean up temporary files
	@echo "Cleaning up temporary files..."
	find . -name "*.tfstate*" -delete
	find . -name ".terraform" -type d -exec rm -rf {} +
	find . -name "tfplan" -delete

docs: ## Generate documentation
	@echo "Generating documentation..."
	cd infra/envs/dev && terraform-docs -c ../../.terraform-docs.yml .

bootstrap: ## Bootstrap the GCS backend bucket
	@echo "Bootstraping GCS backend bucket..."
	@read -p "Enter project ID: " project_id; \
	read -p "Enter bucket name: " bucket_name; \
	./scripts/bootstrap_backend.sh $$project_id $$bucket_name

bootstrap-apis: ## Enable Service Usage API (required before first Terraform run)
	@echo "Enabling Service Usage API..."
	@read -p "Enter project ID: " project_id; \
	./scripts/enable_service_usage_api.sh $$project_id

bootstrap-terraform: ## Bootstrap Service Usage API using Terraform
	@echo "Bootstrapping Service Usage API with Terraform..."
	cd infra/envs/dev && terraform apply -target=google_project_service.service_usage

install-gcloud: ## Install Google Cloud CLI
	@echo "Installing Google Cloud CLI..."
	./scripts/install-gcloud.sh

setup-github-actions: ## Setup GitHub Actions with Workload Identity Federation
	@echo "Setting up GitHub Actions..."
	./scripts/setup-github-actions.sh

init: ## Initialize Terraform
	@echo "Initializing Terraform..."
	cd infra/envs/dev && terraform init

fmt: ## Format Terraform files
	@echo "Formatting Terraform files..."
	cd infra/envs/dev && terraform fmt -recursive

validate: ## Validate Terraform configuration
	@echo "Validating Terraform configuration..."
	cd infra/envs/dev && terraform validate

output: ## Show Terraform outputs
	@echo "Showing Terraform outputs..."
	cd infra/envs/dev && terraform output

cost-estimate: ## Estimate infrastructure costs
	@echo "Estimating infrastructure costs..."
	cd infra/envs/dev && terraform plan -out=tfplan
	@echo "Cost estimation completed. Review the plan output above."

gcp-info: ## Get GCP organization and billing account information
	@echo "Getting GCP information..."
	./scripts/get-gcp-info.sh
