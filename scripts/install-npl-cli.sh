#!/bin/bash
# Install NPL CLI for Replit environment

set -e

echo "📦 Installing NPL CLI..."

# Check if already installed
if command -v npl &> /dev/null; then
    echo "✅ NPL CLI already installed: $(npl version)"
    exit 0
fi

# Install NPL CLI using the official installer
curl -s https://documentation.noumenadigital.com/get-npl-cli.sh | bash

# Add to PATH for current session
export PATH="$HOME/.npl/bin:$PATH"

# Verify installation
if command -v npl &> /dev/null; then
    echo "✅ NPL CLI installed successfully: $(npl version)"
else
    echo "❌ NPL CLI installation failed"
    echo "Please try manual installation from: https://documentation.noumenadigital.com/runtime/tools/build-tools/cli/"
    exit 1
fi
