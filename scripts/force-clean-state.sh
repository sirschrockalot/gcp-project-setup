#!/usr/bin/env bash
set -euo pipefail

# Force clean Terraform state script
# This removes all problematic resources from the state

echo "🧹 Force cleaning Terraform state..."
echo ""

# Check if we're in the right directory
if [[ ! -f "infra/envs/dev/main.tf" ]]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

cd infra/envs/dev

echo "📋 Current Terraform state..."
terraform state list

echo ""
echo "🗑️  Removing problematic resources from state..."

# Remove all workload identity related resources
echo "Removing workload identity resources..."
terraform state rm module.iam.google_iam_workload_identity_pool.github_actions[0] 2>/dev/null || echo "No workload identity pool in state"
terraform state rm module.iam.google_iam_workload_identity_pool_provider.github_actions[0] 2>/dev/null || echo "No workload identity provider in state"
terraform state rm module.iam.google_service_account_iam_binding.workload_identity_binding[0] 2>/dev/null || echo "No workload identity binding in state"

# Remove any other problematic resources that might exist
echo "Removing other potentially problematic resources..."
terraform state rm module.iam.google_project_iam_member.ci_roles 2>/dev/null || echo "No CI roles in state"
terraform state rm module.iam.google_service_account.ci 2>/dev/null || echo "No CI service account in state"

echo ""
echo "✅ State cleanup completed!"
echo ""
echo "📝 Next steps:"
echo "1. Run: terraform plan (to verify no more errors)"
echo "2. If plan succeeds, run: terraform apply"
echo "3. Or trigger GitHub Actions workflow again"
