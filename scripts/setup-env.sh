#!/bin/bash
# Generate environment configuration from tenant and app name
# This script derives all URLs from NPL_TENANT and NPL_APP
#
# Configuration sources (in priority order):
# 1. noumena.config file (recommended - committed to repo)
# 2. Environment variables / Replit Secrets

set -e

echo "🔧 Setting up Noumena Cloud environment..."

# Try to load from noumena.config first
if [ -f "noumena.config" ]; then
    echo "📁 Found noumena.config file"
    # Source the config file (it uses shell variable syntax)
    source noumena.config
fi

# Check if we have the required values
if [ -z "$NPL_TENANT" ]; then
    echo ""
    echo "❌ Error: NPL_TENANT not configured"
    echo ""
    echo "   Option 1 (Recommended): Edit noumena.config file"
    echo "   Option 2: Add NPL_TENANT in Replit's Secrets tab"
    echo ""
    exit 1
fi

if [ -z "$NPL_APP" ]; then
    echo ""
    echo "❌ Error: NPL_APP not configured"
    echo ""
    echo "   Option 1 (Recommended): Edit noumena.config file"
    echo "   Option 2: Add NPL_APP in Replit's Secrets tab"
    echo ""
    exit 1
fi

# Derive URLs from tenant and app name
# Pattern: https://engine-{tenant}-{app}.noumena.cloud
# Pattern: https://keycloak-{tenant}-{app}.noumena.cloud

ENGINE_URL="https://engine-${NPL_TENANT}-${NPL_APP}.noumena.cloud"
KEYCLOAK_URL="https://keycloak-${NPL_TENANT}-${NPL_APP}.noumena.cloud"
KEYCLOAK_REALM="${NPL_APP}"
KEYCLOAK_CLIENT_ID="${NPL_APP}"

echo ""
echo "📋 Derived configuration:"
echo "   NPL_TENANT:            $NPL_TENANT"
echo "   NPL_APP:               $NPL_APP"
echo "   NPL Engine URL:        $ENGINE_URL"
echo "   Keycloak URL:          $KEYCLOAK_URL"
echo "   Keycloak Realm:        $KEYCLOAK_REALM"
echo "   Keycloak Client ID:    $KEYCLOAK_CLIENT_ID"
echo ""

# Export for use by other scripts
export VITE_NPL_ENGINE_URL="$ENGINE_URL"
export VITE_KEYCLOAK_URL="$KEYCLOAK_URL"
export VITE_KEYCLOAK_REALM="$KEYCLOAK_REALM"
export VITE_KEYCLOAK_CLIENT_ID="$KEYCLOAK_CLIENT_ID"

# Create .env file for Vite
cat > .env << EOF
# Auto-generated from NPL_TENANT and NPL_APP
# Regenerate with: ./scripts/setup-env.sh

VITE_NPL_ENGINE_URL=$ENGINE_URL
VITE_KEYCLOAK_URL=$KEYCLOAK_URL
VITE_KEYCLOAK_REALM=$KEYCLOAK_REALM
VITE_KEYCLOAK_CLIENT_ID=$KEYCLOAK_CLIENT_ID

# Set to 'true' to use direct OIDC HTTP calls instead of Keycloak library
# Recommended for Replit development (bypasses iframe auth issues)
VITE_DEV_MODE=true

# Set to 'true' to use proxy endpoints (for local development)
VITE_USE_PROXY=false
EOF

echo "✅ Created .env file with Noumena Cloud configuration"

# Verify the file was created
if [ -f ".env" ]; then
    echo ""
    echo "📄 .env file contents:"
    cat .env
    echo ""
else
    echo "❌ Warning: .env file was not created!"
fi

echo ""
echo "🔗 Useful links:"
echo "   Portal:    https://portal.noumena.cloud/${NPL_TENANT}/${NPL_APP}"
echo "   Swagger:   ${ENGINE_URL}/swagger-ui/index.html"
echo "   Keycloak:  ${KEYCLOAK_URL}/admin/master/console"

echo ""
echo "⚠️  IMPORTANT: For production deployment, set VITE_DEV_MODE=false"
echo "   Run: make build (sets VITE_DEV_MODE=false automatically)"
