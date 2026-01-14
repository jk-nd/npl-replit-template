#!/bin/bash
# Generate environment configuration from tenant and app name
# This script derives all URLs from NPL_TENANT and NPL_APP

set -e

echo "🔧 Setting up Noumena Cloud environment..."

# Check required environment variables
if [ -z "$NPL_TENANT" ]; then
    echo "❌ Error: NPL_TENANT environment variable not set"
    echo "   Add it in Replit's Secrets tab (e.g., 'tim')"
    exit 1
fi

if [ -z "$NPL_APP" ]; then
    echo "❌ Error: NPL_APP environment variable not set"
    echo "   Add it in Replit's Secrets tab (e.g., 'test')"
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
VITE_DEV_MODE=false

# Set to 'true' to use proxy endpoints (for local development)
VITE_USE_PROXY=false
EOF

echo "✅ Created .env file with Noumena Cloud configuration"
echo ""
echo "🔗 Useful links:"
echo "   Portal:    https://portal.noumena.cloud/${NPL_TENANT}/${NPL_APP}"
echo "   Swagger:   ${ENGINE_URL}/swagger-ui/index.html"
echo "   Keycloak:  ${KEYCLOAK_URL}/admin/master/console"
