#!/bin/bash
# Configure Keycloak client settings (redirect URIs, web origins)
# This adds localhost and Replit URLs to the allowed redirect URIs

set -e

echo "🔧 Configuring Keycloak client..."
echo ""

# Source configuration files
if [ -f noumena.config ]; then
    source noumena.config
fi
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check required environment variables
if [ -z "$NPL_TENANT" ] || [ -z "$NPL_APP" ]; then
    echo "❌ Error: NPL_TENANT and NPL_APP must be set"
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

KEYCLOAK_URL="${VITE_KEYCLOAK_URL:-https://keycloak-${NPL_TENANT}-${NPL_APP}.noumena.cloud}"
REALM="${VITE_KEYCLOAK_REALM:-${NPL_APP}}"
CLIENT_ID="${VITE_KEYCLOAK_CLIENT_ID:-${NPL_APP}}"

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
NEW_REDIRECT_URIS='["http://localhost:5000/*", "http://localhost:5173/*", "https://*.replit.dev/*", "https://*.worf.replit.dev/*", "https://*.picard.replit.dev/*", "https://*.kirk.replit.dev/*", "https://*.riker.replit.dev/*", "https://*.repl.co/*", "https://*.noumena.cloud/*"]'
NEW_WEB_ORIGINS='["http://localhost:5000", "http://localhost:5173", "https://*.replit.dev", "https://*.worf.replit.dev", "https://*.picard.replit.dev", "https://*.kirk.replit.dev", "https://*.riker.replit.dev", "https://*.repl.co", "https://*.noumena.cloud"]'

# Auto-detect Replit URL using available environment variables
DETECTED_REPLIT_HOST=""

# Method 1: REPLIT_DEV_DOMAIN (set by Replit for dev URLs)
if [ -n "$REPLIT_DEV_DOMAIN" ]; then
    DETECTED_REPLIT_HOST="$REPLIT_DEV_DOMAIN"
    echo "🔍 Detected via REPLIT_DEV_DOMAIN: $DETECTED_REPLIT_HOST"
fi

# Method 2: Construct from REPL_ID (Replit's unique ID)
if [ -z "$DETECTED_REPLIT_HOST" ] && [ -n "$REPL_ID" ]; then
    # Try common Replit URL patterns
    # Format: <repl-id>-00-<random>.worf.replit.dev or similar
    # We'll add a wildcard pattern for this repl
    echo "🔍 Detected REPL_ID: $REPL_ID"
    # Add patterns that include this REPL_ID
    NEW_REDIRECT_URIS=$(echo "$NEW_REDIRECT_URIS" | jq --arg url "https://${REPL_ID}*.replit.dev/*" '. += [$url]')
    NEW_REDIRECT_URIS=$(echo "$NEW_REDIRECT_URIS" | jq --arg url "https://${REPL_ID}*.worf.replit.dev/*" '. += [$url]')
fi

# Method 3: REPL_SLUG + REPL_OWNER (older format)
if [ -z "$DETECTED_REPLIT_HOST" ] && [ -n "$REPL_SLUG" ] && [ -n "$REPL_OWNER" ]; then
    DETECTED_REPLIT_HOST="${REPL_SLUG}.${REPL_OWNER}.repl.co"
    echo "🔍 Detected via REPL_SLUG/OWNER: $DETECTED_REPLIT_HOST"
fi

# Method 4: Check REPLIT_DOMAINS (might be set in some environments)
if [ -z "$DETECTED_REPLIT_HOST" ] && [ -n "$REPLIT_DOMAINS" ]; then
    DETECTED_REPLIT_HOST=$(echo "$REPLIT_DOMAINS" | cut -d',' -f1)
    echo "🔍 Detected via REPLIT_DOMAINS: $DETECTED_REPLIT_HOST"
fi

# Method 5: Manual override via REPLIT_URL
if [ -n "$REPLIT_URL" ]; then
    DETECTED_REPLIT_HOST=$(echo "$REPLIT_URL" | sed 's|https://||' | sed 's|http://||' | sed 's|/$||')
    echo "🔍 Using manual REPLIT_URL: $DETECTED_REPLIT_HOST"
fi

# Add the detected host to redirect URIs
if [ -n "$DETECTED_REPLIT_HOST" ]; then
    NEW_REDIRECT_URIS=$(echo "$NEW_REDIRECT_URIS" | jq --arg url "https://${DETECTED_REPLIT_HOST}/*" '. += [$url]')
    NEW_WEB_ORIGINS=$(echo "$NEW_WEB_ORIGINS" | jq --arg url "https://${DETECTED_REPLIT_HOST}" '. += [$url]')
fi

# Debug: Show available Replit env vars
echo ""
echo "📋 Available Replit environment variables:"
env | grep -i repl | sed 's/=.*/=***/' || echo "   (none found - not running on Replit?)"
echo ""

# Merge with existing (remove duplicates)
MERGED_REDIRECTS=$(echo "$CURRENT_REDIRECTS $NEW_REDIRECT_URIS" | jq -s 'add | unique')
MERGED_ORIGINS=$(echo "$CURRENT_ORIGINS $NEW_WEB_ORIGINS" | jq -s 'add | unique')

echo "📝 Updating client with:"
echo "   Redirect URIs: $MERGED_REDIRECTS"
echo "   Web Origins:   $MERGED_ORIGINS"
echo ""

# Update the client
# Enable Direct Access Grants for password-based login (required for dev mode in Replit)
# This is less secure than authorization code flow but necessary when iframes break standard auth
echo "🔓 Enabling Direct Access Grants for dev mode..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${CLIENT_UUID}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(echo "$CLIENT_CONFIG" | jq --argjson redirects "$MERGED_REDIRECTS" --argjson origins "$MERGED_ORIGINS" \
        '.redirectUris = $redirects | .webOrigins = $origins | .directAccessGrantsEnabled = true')")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" == "204" ]; then
    echo "✅ Client updated (redirect URIs + Direct Access Grants enabled)"
else
    echo "❌ Failed to update client (HTTP $HTTP_CODE)"
    echo "$RESPONSE" | head -n-1
    exit 1
fi

# Update realm security headers to allow iframe embedding
echo ""
echo "🖼️  Configuring realm to allow iframe embedding..."

# Get current realm config
REALM_CONFIG=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")

# Update browser security headers to allow framing from Replit
# Set Content-Security-Policy frame-ancestors to allow Replit domains
# IMPORTANT: Must include replit.com (the main UI) AND replit.dev (the preview)

# Base CSP with all Replit patterns + Noumena Cloud (for deployed frontends)
CSP_FRAME_ANCESTORS="'self' https://replit.com https://*.replit.com https://*.replit.dev https://*.worf.replit.dev https://*.picard.replit.dev https://*.kirk.replit.dev https://*.riker.replit.dev https://*.repl.co http://localhost:* https://*.noumena.cloud"

# Add specific detected Replit host if available (wildcards don't always match)
if [ -n "$DETECTED_REPLIT_HOST" ]; then
    CSP_FRAME_ANCESTORS="$CSP_FRAME_ANCESTORS https://${DETECTED_REPLIT_HOST}"
    echo "   Adding specific host to CSP: $DETECTED_REPLIT_HOST"
fi

NEW_CSP="frame-src 'self'; frame-ancestors ${CSP_FRAME_ANCESTORS}; object-src 'none';"

UPDATED_REALM=$(echo "$REALM_CONFIG" | jq --arg csp "$NEW_CSP" '
    .browserSecurityHeaders.contentSecurityPolicy = $csp |
    .browserSecurityHeaders.xFrameOptions = ""
')

REALM_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$UPDATED_REALM")

REALM_HTTP_CODE=$(echo "$REALM_RESPONSE" | tail -n1)

if [ "$REALM_HTTP_CODE" == "204" ]; then
    echo "✅ Iframe embedding enabled for Replit domains"
else
    echo "⚠️  Could not update realm security headers (HTTP $REALM_HTTP_CODE)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Keycloak client configured successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Configuration applied:"
echo "   • Redirect URIs: localhost:5000, localhost:5173, *.replit.dev, *.noumena.cloud"
echo "   • Direct Access Grants: ENABLED (for dev mode password login)"
echo "   • Iframe embedding: ENABLED (for Replit webview)"
echo ""
echo "⚠️  Note: Direct Access Grants is less secure than standard OAuth flow."
echo "   This is acceptable for development but should be disabled in production."
