#!/bin/bash
# Install NPL CLI for Replit environment

set -e

echo "📦 Installing NPL CLI..."

# Add to PATH for current session
export PATH="$HOME/.npl/bin:$PATH"

# Check if already installed
if command -v npl &> /dev/null; then
    echo "✅ NPL CLI already installed: $(npl version)"
    exit 0
fi

# Create installation directory
mkdir -p "$HOME/.npl/bin"

# Download and run installer, but skip bashrc modification by making it non-writable temporarily
# or download the binary directly

# Try to download the installer and modify it to skip shell config
INSTALLER=$(curl -s https://documentation.noumenadigital.com/get-npl-cli.sh)

# Run installer but ignore errors about bashrc (|| true to continue on non-zero exit)
echo "$INSTALLER" | bash || true

# Verify installation
if [ -f "$HOME/.npl/bin/npl" ]; then
    chmod +x "$HOME/.npl/bin/npl"
    echo "✅ NPL CLI installed successfully"
    "$HOME/.npl/bin/npl" version || true
else
    echo "❌ NPL CLI installation failed"
    echo "Please try manual installation from: https://documentation.noumenadigital.com/runtime/tools/build-tools/cli/"
    exit 1
fi
