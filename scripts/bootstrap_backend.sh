#!/bin/bash
set -euo pipefail

# Bootstrap script for GCS backend bucket
# This script creates the GCS bucket needed for Terraform state

PROJECT_ID="${1:-}"
BUCKET_NAME="${2:-}"

if [[ -z "$PROJECT_ID" || -z "$BUCKET_NAME" ]]; then
    echo "Usage: $0 <project-id> <bucket-name>"
    echo "Example: $0 presidentialdigs-dev tfstate-presidentialdigs-dev"
    exit 1
fi

echo "Setting up GCS backend bucket for Terraform state..."

# Create the bucket
echo "Creating bucket gs://$BUCKET_NAME in project $PROJECT_ID..."
gsutil mb -p "$PROJECT_ID" -c STANDARD -l us-central1 "gs://$BUCKET_NAME"

# Enable versioning
echo "Enabling versioning..."
gsutil versioning set on "gs://$BUCKET_NAME"

# Enable uniform bucket-level access
echo "Enabling uniform bucket-level access..."
gsutil iam ch allUsers:objectViewer "gs://$BUCKET_NAME" 2>/dev/null || {
    echo "⚠️  Could not set public read access - this is normal if customer domain restrictions are enabled"
    echo "   The bucket will still work for Terraform state storage"
}

echo ""
echo "✅ GCS backend bucket '$BUCKET_NAME' created successfully!"
echo "   Project: $PROJECT_ID"
echo "   Location: us-central1"
echo "   Versioning: Enabled"
echo ""
echo "You can now run 'terraform init' in your environment directory."
echo ""
echo "Note: If you see warnings about IAM policies, this is normal and expected"
echo "      when customer domain restrictions are enabled in your organization."
