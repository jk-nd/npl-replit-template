#!/bin/bash
# Bootstrap script template - Creates initial protocol instances after deployment
#
# IMPORTANT: This script is a TEMPLATE. You must customize it for your specific protocol.
#
# Usage: make bootstrap (after adding a bootstrap target to Makefile)
#
# The bootstrap problem:
#   Before any protocol instances exist, users can't interact with the app.
#   This script creates the initial instances needed to bootstrap the application.
#
# Example scenarios:
#   - Create an initial Registry/Store that users can then register with
#   - Create initial inventory items
#   - Set up admin accounts

set -e

echo "🚀 Bootstrapping initial data..."
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
    echo "   Run 'make setup' first"
    exit 1
fi

# Build URLs
ENGINE_URL="https://engine-${NPL_TENANT}-${NPL_APP}.noumena.cloud"
KEYCLOAK_URL="https://keycloak-${NPL_TENANT}-${NPL_APP}.noumena.cloud"
REALM="${NPL_APP}"

# Admin credentials for authentication
if [ -z "$BOOTSTRAP_USER" ] || [ -z "$BOOTSTRAP_PASSWORD" ]; then
    echo "⚠️  BOOTSTRAP_USER and BOOTSTRAP_PASSWORD not set"
    echo "   Using default test user: alice / password123456"
    BOOTSTRAP_USER="alice"
    BOOTSTRAP_PASSWORD="password123456"
fi

echo "📡 Engine URL: ${ENGINE_URL}"
echo "🔐 Authenticating as: ${BOOTSTRAP_USER}"
echo ""

# Get access token
echo "🔐 Getting access token..."
TOKEN_RESPONSE=$(curl -s -X POST "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
    -d "client_id=${REALM}" \
    -d "username=${BOOTSTRAP_USER}" \
    -d "password=${BOOTSTRAP_PASSWORD}" \
    -d "grant_type=password")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Authentication failed"
    echo "$TOKEN_RESPONSE" | jq -r '.error_description // .error // "Unknown error"'
    exit 1
fi
echo "✅ Authenticated"
echo ""

# ============================================================
# CUSTOMIZE BELOW: Add your bootstrap API calls here
# ============================================================

# Example: Create a registry/store instance
# Replace 'YourPackage' and 'YourProtocol' with your actual package and protocol names
# Replace the @parties and parameters with your protocol's requirements

PACKAGE="demo"  # TODO: Change to your package name

echo "📦 Creating initial protocol instance..."

# Example POST request to create a protocol instance:
#
# RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${ENGINE_URL}/npl/${PACKAGE}/YourRegistry/" \
#     -H "Authorization: Bearer ${ACCESS_TOKEN}" \
#     -H "Content-Type: application/json" \
#     -d '{
#       "@parties": {
#         "admin": {
#           "claims": {
#             "email": ["admin@example.com"]
#           }
#         }
#       },
#       "name": "Main Registry"
#     }')
#
# HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
# BODY=$(echo "$RESPONSE" | head -n-1)
#
# if [ "$HTTP_CODE" == "201" ] || [ "$HTTP_CODE" == "200" ]; then
#     echo "✅ Registry created!"
#     echo "$BODY" | jq -r '.["@id"]'
# else
#     echo "⚠️  Failed to create registry (HTTP $HTTP_CODE)"
#     echo "$BODY"
# fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  This is a TEMPLATE script!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To use this script:"
echo "1. Edit scripts/bootstrap.sh"
echo "2. Uncomment and customize the curl commands above"
echo "3. Change PACKAGE to your package name"
echo "4. Update the @parties and body to match your protocol"
echo "5. Add 'make bootstrap' target to Makefile"
echo ""
echo "See docs/NPL_FRONTEND_DEVELOPMENT.md section 9 for details."
