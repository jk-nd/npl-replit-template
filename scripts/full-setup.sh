#!/bin/bash
# Full setup: configure env, install deps, deploy NPL, generate client

set -e

echo "⚡ Starting full setup..."
echo ""

# Step 1: Generate environment configuration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1/5: Setting up Noumena Cloud configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check required environment variables (only need tenant and app name!)
if [ -z "$NPL_TENANT" ] || [ -z "$NPL_APP_NAME" ]; then
    echo "❌ Missing required Secrets. Please add these in Replit's Secrets tab:"
    echo ""
    echo "   NPL_TENANT     - Your Noumena Cloud tenant (e.g., 'tim')"
    echo "   NPL_APP_NAME   - Your Noumena Cloud app (e.g., 'test')"
    echo ""
    echo "📝 Find these at: https://portal.noumena.cloud"
    echo "   The URL shows: portal.noumena.cloud/{tenant}/{app}"
    exit 1
fi

# Run environment setup to generate .env file
./scripts/setup-env.sh

# Source the .env file for this script
export $(grep -v '^#' .env | xargs)
echo ""

# Step 2: Install NPL CLI
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2/5: Installing NPL CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/install-npl-cli.sh
export PATH="$HOME/.npl/bin:$PATH"
echo ""

# Step 3: Install npm dependencies
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3/5: Installing npm dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
npm install
echo ""

# Step 4: Login and deploy
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4/5: Deploying NPL to Noumena Cloud"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔐 You may be prompted to log in to Noumena Cloud..."
echo ""

# Check NPL code first
echo "✅ Checking NPL code..."
npl check --source-dir ./npl/src/main

# Deploy NPL
./scripts/deploy-to-cloud.sh
echo ""

# Step 5: Generate client
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5/5: Generating API client from OpenAPI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/generate-client.sh
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 Click 'Run' to start your React frontend!"
echo ""
echo "📖 Your app will connect to:"
echo "   NPL Engine: $VITE_NPL_ENGINE_URL"
echo "   Keycloak:   $VITE_KEYCLOAK_URL"
