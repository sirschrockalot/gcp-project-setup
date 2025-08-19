#!/usr/bin/env bash
set -euo pipefail

# Install Google Cloud CLI on macOS
echo "🔧 Installing Google Cloud CLI..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Install Google Cloud CLI
echo "📦 Installing Google Cloud CLI via Homebrew..."
brew install --cask google-cloud-sdk

# Add to PATH for current session
export PATH="/usr/local/share/google-cloud-sdk/bin:$PATH"

# Initialize gcloud
echo "🚀 Initializing Google Cloud CLI..."
gcloud init

echo "✅ Google Cloud CLI installed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Authenticate: gcloud auth login"
echo "2. Set your project: gcloud config set project presidentialdigs-dev"
echo "3. Enable Service Usage API: ./scripts/enable_service_usage_api.sh presidentialdigs-dev"
echo "4. Run Terraform: make plan"
