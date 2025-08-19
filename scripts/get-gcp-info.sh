#!/bin/bash
set -euo pipefail

echo "🔍 Getting GCP Organization and Billing Account Information..."
echo "=================================================="

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud SDK is not installed or not in PATH"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ You are not authenticated with gcloud"
    echo "Please run: gcloud auth login"
    exit 1
fi

echo "✅ Authenticated as: $(gcloud config get-value account)"
echo ""

# Get Organization ID
echo "🏢 **Organization Information:**"
echo "--------------------------------"
if gcloud organizations list --format="value(organizationId)" | grep -q .; then
    ORG_ID=$(gcloud organizations list --format="value(organizationId)" | head -1)
    ORG_NAME=$(gcloud organizations list --format="value(displayName)" | head -1)
    echo "Organization ID: $ORG_ID"
    echo "Organization Name: $ORG_NAME"
else
    echo "ℹ️  No organization found - you might be using a personal account"
    echo "   You can set org_id to null in terraform.tfvars"
    ORG_ID="null"
fi

echo ""

# Get Billing Account ID
echo "💳 **Billing Account Information:**"
echo "-----------------------------------"
if gcloud billing accounts list --format="value(accountId)" | grep -q .; then
    BILLING_ID=$(gcloud billing accounts list --format="value(accountId)" | head -1)
    BILLING_NAME=$(gcloud billing accounts list --format="value(name)" | head -1)
    echo "Billing Account ID: $BILLING_ID"
    echo "Billing Account Name: $BILLING_NAME"
else
    echo "❌ No billing accounts found"
    echo "   Please ensure you have billing set up in Google Cloud Console"
    exit 1
fi

echo ""

# Get current project
echo "📁 **Current Project:**"
echo "----------------------"
CURRENT_PROJECT=$(gcloud config get-value project)
if [[ "$CURRENT_PROJECT" != "(unset)" ]]; then
    echo "Current Project ID: $CURRENT_PROJECT"
else
    echo "ℹ️  No project currently set"
    echo "   You can set one with: gcloud config set project PROJECT_ID"
fi

echo ""
echo "=================================================="
echo "📋 **Copy these values to your terraform.tfvars file:**"
echo ""

if [[ "$ORG_ID" != "null" ]]; then
    echo "org_id = \"$ORG_ID\""
else
    echo "# org_id = null  # Personal account, no organization"
fi

echo "billing_account = \"$BILLING_ID\""
echo ""

echo "💡 **Next Steps:**"
echo "1. Copy the values above to infra/envs/dev/terraform.tfvars"
echo "2. Run: make bootstrap"
echo "3. Run: make init"
echo "4. Run: make plan"
echo "5. Run: make apply"
