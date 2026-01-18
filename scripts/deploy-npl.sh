#!/bin/bash
# Deploy NPL protocols to Noumena Cloud

set -e

echo "☁️  Deploying NPL protocols to Noumena Cloud..."

# Ensure NPL CLI is in PATH
export PATH="$HOME/.npl/bin:$PATH"

# Check if logged in before attempting deploy
if ! npl cloud status &>/dev/null; then
    echo "❌ Not logged in to Noumena Cloud"
    echo ""
    echo "   Please run: make login"
    echo "   Or:         npl cloud login"
    echo ""
    exit 1
fi

# Source configuration files
if [ -f noumena.config ]; then
    source noumena.config
fi
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check required environment variables
if [ -z "$NPL_TENANT" ]; then
    echo "❌ Error: NPL_TENANT not set"
    echo "   Add it in Replit's Secrets tab"
    exit 1
fi

if [ -z "$NPL_APP" ]; then
    echo "❌ Error: NPL_APP not set"
    echo "   Add it in Replit's Secrets tab"
    exit 1
fi

echo "   Tenant: $NPL_TENANT"
echo "   App:    $NPL_APP"
echo ""

# Deploy NPL protocols using the CLI
npl cloud deploy npl \
    --tenant "$NPL_TENANT" \
    --app "$NPL_APP" \
    --migration "./npl/src/main/migration.yml"

echo ""
echo "✅ NPL protocols deployed successfully!"
echo ""
echo "🔗 View in portal: https://portal.noumena.cloud/${NPL_TENANT}/${NPL_APP}"
