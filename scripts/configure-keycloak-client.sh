#!/bin/bash
# Configure Keycloak client settings (redirect URIs, web origins)
# This adds localhost and Replit URLs to the allowed redirect URIs

set -e

echo "🔧 Configuring Keycloak client..."
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

# Keycloak admin credentials
if [ -z "$KEYCLOAK_ADMIN_USER" ] || [ -z "$KEYCLOAK_ADMIN_PASSWORD" ]; then
    echo "❌ Error: Keycloak admin credentials not set"
    echo ""
    echo "   Please set these environment variables:"
    echo "   - KEYCLOAK_ADMIN_USER"
    echo "   - KEYCLOAK_ADMIN_PASSWORD"
    exit 1
fi

KEYCLOAK_URL="${VITE_KEYCLOAK_URL:-https://keycloak-${NPL_TENANT}-${NPL_APP_NAME}.noumena.cloud}"
REALM="${VITE_KEYCLOAK_REALM:-${NPL_APP_NAME}}"
CLIENT_ID="${VITE_KEYCLOAK_CLIENT_ID:-${NPL_APP_NAME}}"

echo "📋 Configuration:"
echo "   Keycloak URL: $KEYCLOAK_URL"
echo "   Realm:        $REALM"
echo "   Client ID:    $CLIENT_ID"
echo ""

# Get admin access token
echo "🔐 Authenticating as admin..."
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=password" \
    --data-urlencode "client_id=admin-cli" \
    --data-urlencode "username=${KEYCLOAK_ADMIN_USER}" \
    --data-urlencode "password=${KEYCLOAK_ADMIN_PASSWORD}" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" == "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ Failed to authenticate as admin"
    exit 1
fi
echo "✅ Authenticated"
echo ""

# Get the client's internal ID (UUID)
echo "🔍 Finding client '$CLIENT_ID'..."
CLIENT_UUID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients?clientId=${CLIENT_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

if [ "$CLIENT_UUID" == "null" ] || [ -z "$CLIENT_UUID" ]; then
    echo "❌ Client '$CLIENT_ID' not found in realm '$REALM'"
    exit 1
fi
echo "✅ Found client (UUID: $CLIENT_UUID)"
echo ""

# Get current client config
echo "📥 Fetching current client configuration..."
CLIENT_CONFIG=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${CLIENT_UUID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")

# Extract current redirect URIs and web origins
CURRENT_REDIRECTS=$(echo "$CLIENT_CONFIG" | jq -r '.redirectUris // []')
CURRENT_ORIGINS=$(echo "$CLIENT_CONFIG" | jq -r '.webOrigins // []')

echo "   Current redirect URIs: $CURRENT_REDIRECTS"
echo "   Current web origins:   $CURRENT_ORIGINS"
echo ""

# Define the URIs we want to add
# - localhost for local development
# - Various Replit URL patterns (they use different subdomains)
NEW_REDIRECT_URIS='["http://localhost:5173/*", "https://*.replit.dev/*", "https://*.worf.replit.dev/*", "https://*.picard.replit.dev/*", "https://*.kirk.replit.dev/*", "https://*.repl.co/*"]'
NEW_WEB_ORIGINS='["http://localhost:5173", "https://*.replit.dev", "https://*.worf.replit.dev", "https://*.picard.replit.dev", "https://*.kirk.replit.dev", "https://*.repl.co"]'

# Merge with existing (remove duplicates)
MERGED_REDIRECTS=$(echo "$CURRENT_REDIRECTS $NEW_REDIRECT_URIS" | jq -s 'add | unique')
MERGED_ORIGINS=$(echo "$CURRENT_ORIGINS $NEW_WEB_ORIGINS" | jq -s 'add | unique')

echo "📝 Updating client with:"
echo "   Redirect URIs: $MERGED_REDIRECTS"
echo "   Web Origins:   $MERGED_ORIGINS"
echo ""

# Update the client
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${CLIENT_UUID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(echo "$CLIENT_CONFIG" | jq --argjson redirects "$MERGED_REDIRECTS" --argjson origins "$MERGED_ORIGINS" \
        '.redirectUris = $redirects | .webOrigins = $origins')")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" == "204" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Keycloak client configured successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📝 The following redirect URIs are now allowed:"
    echo "   • http://localhost:5173/* (local development)"
    echo "   • https://*.replit.dev/*  (Replit deployments)"
    echo "   • https://*.repl.co/*     (Replit legacy URLs)"
else
    echo "❌ Failed to update client (HTTP $HTTP_CODE)"
    echo "$RESPONSE" | head -n-1
    exit 1
fi
