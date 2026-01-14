#!/bin/bash
# Full setup: configure env, install deps, create app

set -e

echo "⚡ Starting full setup..."
echo ""

# Step 1: Generate environment configuration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1/4: Setting up Noumena Cloud configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check required environment variables (only need tenant and app name!)
if [ -z "$NPL_TENANT" ] || [ -z "$NPL_APP" ]; then
    echo "❌ Missing required Secrets. Please add these in Replit's Secrets tab:"
    echo ""
    echo "   NPL_TENANT     - Your Noumena Cloud tenant (e.g., 'tim')"
    echo "   NPL_APP        - Your Noumena Cloud app (e.g., 'test')"
    echo ""
    echo "📝 Find these at: https://portal.noumena.cloud"
    echo "   The URL shows: portal.noumena.cloud/{tenant}/{app}"
    exit 1
fi
echo ""

# Create the app on Noumena Cloud (idempotent - won't fail if already exists)
echo "☁️  Creating app on Noumena Cloud..."
if npl cloud create --tenant "$NPL_TENANT" --app-name "$NPL_APP" 2>&1; then
    echo "✅ App created or already exists"
else
    echo "⚠️  App creation failed or already exists - continuing..."
fi

# Run environment setup to generate .env file
./scripts/setup-env.sh

# Source the .env file for this script
export $(grep -v '^#' .env | xargs)
echo ""

# Step 2: Install NPL CLI
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2/4: Installing NPL CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/install-npl-cli.sh
export PATH="$HOME/.npl/bin:$PATH"
echo ""

# Step 3: Install npm dependencies
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3/4: Installing npm dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd frontend && npm install && cd ..
echo ""

# Step 4: Create app on Noumena Cloud
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4/4: Creating app on Noumena Cloud"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check NPL code first
echo "✅ Checking NPL code..."
npl check --source-dir ./npl/src/main
echo ""

# Create the app on Noumena Cloud (idempotent - won't fail if already exists)
echo "☁️  Creating app on Noumena Cloud..."
if npl cloud create --tenant "$NPL_TENANT" --app-name "$NPL_APP" 2>&1; then
    echo "✅ App created or already exists"
else
    echo "⚠️  App creation failed or already exists - continuing..."
fi
echo ""

# Wait for app to be ready
echo "⏳ Checking app status..."
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if npl cloud status 2>&1 | grep -q "$NPL_APP.*\[active\].*🟢"; then
        echo "✅ App is ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "⏳ App not ready yet, waiting... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 5
    else
        echo "⚠️  App status check timed out, proceeding anyway..."
    fi
done
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Next steps:"
echo ""
echo "   1. Deploy NPL:            Use '🚀 Deploy NPL' workflow"
echo "   2. Provision test users:  Use '👥 Provision Users' workflow"
echo "   3. Configure Keycloak:    Use '🔑 Configure Keycloak' workflow"
echo "   4. Click 'Run' or use '▶️ Start Dev Server' workflow!"
echo ""
echo "📖 Your app will connect to:"
echo "   NPL Engine: $VITE_NPL_ENGINE_URL"
echo "   Keycloak:   $VITE_KEYCLOAK_URL"
