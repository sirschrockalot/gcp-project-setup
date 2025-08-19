#!/bin/bash
set -euo pipefail

echo "Running Terraform quality checks..."

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "Installing pre-commit..."
    pip install pre-commit
fi

# Install pre-commit hooks
pre-commit install

# Run all checks
pre-commit run --all-files

echo "✅ All quality checks passed!"
