#!/usr/bin/env bash
set -euo pipefail

# Script to clean up Workload Identity resources from Terraform state
# This is needed because we're managing these resources manually now

echo "🔧 Cleaning up Workload Identity resources from Terraform state..."
echo ""

# Check if we're in the right directory
if [[ ! -f "infra/envs/dev/main.tf" ]]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

cd infra/envs/dev

echo "📋 Current Terraform state..."
terraform state list | grep -E "(workload|identity)" || echo "No workload identity resources found in state"

echo ""
echo "🗑️  Removing Workload Identity resources from state (if they exist)..."

# Remove IAM module resources
terraform state rm module.iam.google_iam_workload_identity_pool.github_actions[0] 2>/dev/null || echo "No workload identity pool in state"
terraform state rm module.iam.google_iam_workload_identity_pool_provider.github_actions[0] 2>/dev/null || echo "No workload identity provider in state"
terraform state rm module.iam.google_service_account_iam_binding.workload_identity_binding[0] 2>/dev/null || echo "No workload identity binding in state"

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "📝 Next steps:"
echo "1. Run: terraform plan (to verify no more workload identity errors)"
echo "2. If plan succeeds, run: terraform apply"
echo "3. Or trigger GitHub Actions workflow again"
