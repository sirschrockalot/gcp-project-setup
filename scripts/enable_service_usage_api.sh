#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script to enable Service Usage API
# This is required before Terraform can manage other Google Cloud APIs

PROJECT_ID="${1:-}"
REGION="${2:-us-central1}"

if [[ -z "$PROJECT_ID" ]]; then
    echo "Usage: $0 <project-id> [region]"
    echo "Example: $0 presidentialdigs-dev us-central1"
    exit 1
fi

echo "🔧 Enabling Service Usage API for project: $PROJECT_ID"

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Not authenticated with gcloud. Please run: gcloud auth login"
    exit 1
fi

# Set the project
echo "📋 Setting project to: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

# Enable Service Usage API
echo "🚀 Enabling Service Usage API..."
gcloud services enable serviceusage.googleapis.com --project="$PROJECT_ID"

# Wait for the API to be fully enabled
echo "⏳ Waiting for Service Usage API to be fully enabled..."
sleep 30

# Verify the API is enabled
echo "✅ Verifying Service Usage API is enabled..."
if gcloud services list --enabled --filter="name:serviceusage.googleapis.com" --project="$PROJECT_ID" | grep -q "serviceusage.googleapis.com"; then
    echo "✅ Service Usage API is now enabled!"
    echo "🎉 You can now run Terraform to manage other APIs"
else
    echo "❌ Service Usage API is not yet enabled. Please wait a few minutes and try again."
    exit 1
fi

echo ""
echo "📝 Next steps:"
echo "1. Run: terraform init"
echo "2. Run: terraform plan"
echo "3. Run: terraform apply"
