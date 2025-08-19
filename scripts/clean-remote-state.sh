#!/usr/bin/env bash
set -euo pipefail

# Clean Remote Terraform State Script
# This removes problematic resources from the remote GCS state

echo "🧹 Cleaning Remote Terraform State"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [[ ! -f "infra/envs/dev/main.tf" ]]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

cd infra/envs/dev

echo "This script will:"
echo "1. Initialize Terraform with the remote backend"
echo "2. Remove problematic Workload Identity resources from state"
echo "3. Clean up the remote state"
echo ""

read -p "⚠️  Continue? This will modify the remote Terraform state! (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Remote state cleanup cancelled"
    exit 0
fi

echo ""
print_info "Initializing Terraform with remote backend..."

# Initialize Terraform (this will connect to the remote GCS state)
terraform init

echo ""
print_info "Current remote state resources:"
terraform state list

echo ""
print_info "Removing problematic Workload Identity resources from remote state..."

# Remove the problematic resources from remote state
terraform state rm module.iam.google_service_account_iam_binding.workload_identity_binding[0] 2>/dev/null || print_warning "No workload identity binding in state"
terraform state rm module.iam.google_iam_workload_identity_pool_provider.github_actions[0] 2>/dev/null || print_warning "No workload identity provider in state"
terraform state rm module.iam.google_iam_workload_identity_pool.github_actions[0] 2>/dev/null || print_warning "No workload identity pool in state"

echo ""
print_info "Updated remote state:"
terraform state list

echo ""
print_success "Remote state cleanup completed!"
echo ""
echo "📝 Next steps:"
echo "1. The problematic resources have been removed from remote state"
echo "2. Trigger GitHub Actions workflow again"
echo "3. Deployment should now proceed without permission errors"
echo ""
echo "🚀 To deploy:"
echo "   - Make a change to any file in infra/ directory"
echo "   - Commit and push to trigger the workflow"
echo "   - Or manually trigger via GitHub Actions"
