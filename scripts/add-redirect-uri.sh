#!/bin/bash
# Add a custom redirect URI to Keycloak for hosting frontend on external platforms (e.g., Replit)
# Usage: ./scripts/add-redirect-uri.sh <your-app-url>
# Example: ./scripts/add-redirect-uri.sh https://my-app--username.replit.app

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <app-url>"
    echo "Example: $0 https://my-bike-app--username.replit.app"
    exit 1
fi

APP_URL="$1"
APP_URL="${APP_URL%/}"

# Source configuration files
if [ -f noumena.config ]; then
    source noumena.config
fi
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Derive Keycloak URL from NPL_TENANT and NPL_APP if not set
if [ -z "$VITE_KEYCLOAK_URL" ] && [ -n "$NPL_TENANT" ] && [ -n "$NPL_APP" ]; then
    VITE_KEYCLOAK_URL="https://keycloak-${NPL_TENANT}-${NPL_APP}.noumena.cloud"
fi

KEYCLOAK_URL="${VITE_KEYCLOAK_URL}"
REALM="${VITE_KEYCLOAK_REALM:-${NPL_APP}}"
CLIENT_ID="${VITE_KEYCLOAK_CLIENT_ID:-${NPL_APP}}"
ADMIN_USER="${KEYCLOAK_ADMIN_USER}"
ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD}"

if [ -z "$KEYCLOAK_URL" ]; then
    echo "❌ Error: Cannot determine Keycloak URL"
    echo "   Run 'make env' first or set VITE_KEYCLOAK_URL"
    exit 1
fi

if [ -z "$ADMIN_USER" ] || [ -z "$ADMIN_PASSWORD" ]; then
    echo "❌ Error: KEYCLOAK_ADMIN_USER and KEYCLOAK_ADMIN_PASSWORD must be set"
    echo "   Add these in Replit's Secrets tab"
    exit 1
fi

echo "🔗 Adding redirect URI: ${APP_URL}"
echo "   Keycloak: ${KEYCLOAK_URL}"
echo "   Realm: ${REALM}"
echo "   Client: ${CLIENT_ID}"
echo ""

echo "🔐 Authenticating with Keycloak..."
TOKEN_RESPONSE=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
    -d "client_id=admin-cli" \
    -d "username=${ADMIN_USER}" \
    -d "password=${ADMIN_PASSWORD}" \
    -d "grant_type=password")

ADMIN_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" == "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ Authentication failed"
    echo "$TOKEN_RESPONSE" | jq -r '.error_description // .error // "Unknown error"'
    exit 1
fi
echo "✅ Authenticated"

echo "🔍 Finding client '${CLIENT_ID}'..."
CLIENTS=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients?clientId=${CLIENT_ID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")

CLIENT_UUID=$(echo "$CLIENTS" | jq -r '.[0].id')

if [ "$CLIENT_UUID" == "null" ] || [ -z "$CLIENT_UUID" ]; then
    echo "❌ Client not found"
    exit 1
fi
echo "✅ Found client (UUID: ${CLIENT_UUID})"

echo "📥 Fetching current configuration..."
CLIENT_CONFIG=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${CLIENT_UUID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")

CURRENT_REDIRECTS=$(echo "$CLIENT_CONFIG" | jq -r '.redirectUris')

echo "   Current redirect URIs: $(echo "$CURRENT_REDIRECTS" | jq -r 'length') entries"

if echo "$CURRENT_REDIRECTS" | jq -e ". | index(\"${APP_URL}/*\")" > /dev/null 2>&1; then
    echo "✅ Redirect URI already configured"
    exit 0
fi

echo "📝 Adding new redirect URI..."
UPDATED_CONFIG=$(echo "$CLIENT_CONFIG" | jq \
    --arg redirect "${APP_URL}/*" \
    --arg origin "${APP_URL}" \
    '.redirectUris += [$redirect] | .redirectUris |= unique | .webOrigins += [$origin] | .webOrigins |= unique')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${CLIENT_UUID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$UPDATED_CONFIG")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" == "204" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Redirect URI added successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "You can now authenticate from: ${APP_URL}"
    echo ""
else
    echo "❌ Failed to update client (HTTP $HTTP_CODE)"
    echo "$RESPONSE" | head -n-1
    exit 1
fi
