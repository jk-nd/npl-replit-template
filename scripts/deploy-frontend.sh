#!/bin/bash
# Deploy frontend to Noumena Cloud

set -e

echo "🌐 Deploying frontend to Noumena Cloud..."
echo ""

# Source .env if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check required environment variables
if [ -z "$NPL_TENANT" ] || [ -z "$NPL_APP_NAME" ]; then
    echo "❌ Error: NPL_TENANT and NPL_APP_NAME must be set"
    echo "   Run './scripts/setup-env.sh' first"
    exit 1
fi

# Ensure NPL CLI is in PATH
export PATH="$HOME/.npl/bin:$PATH"

# Build the frontend
echo "📦 Building frontend..."
npm run build

# Deploy to cloud
echo "☁️ Deploying to $NPL_TENANT/$NPL_APP_NAME..."
npl cloud deploy frontend \
    --tenant "$NPL_TENANT" \
    --app "$NPL_APP_NAME" \
    --frontend ./dist

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Frontend deployment complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔗 Your frontend is now live at:"
echo "   https://${NPL_TENANT}-${NPL_APP_NAME}.noumena.cloud"
