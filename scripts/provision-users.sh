#!/bin/bash
# Provision seed users in Keycloak for development
# Based on: https://documentation.noumenadigital.com/runtime/deployment/configuration/Engine-Dev-Mode/

set -e

echo "👥 Provisioning seed users in Keycloak..."
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

# Keycloak admin credentials (from Noumena Cloud Portal > Services > Keycloak)
if [ -z "$KEYCLOAK_ADMIN_USER" ] || [ -z "$KEYCLOAK_ADMIN_PASSWORD" ]; then
    echo "❌ Error: Keycloak admin credentials not set"
    echo ""
    echo "   Please add these secrets in Replit (from Noumena Cloud Portal):"
    echo "   - KEYCLOAK_ADMIN_USER     (found in Portal > Services > Keycloak)"
    echo "   - KEYCLOAK_ADMIN_PASSWORD (found in Portal > Services > Keycloak)"
    echo ""
    echo "   Portal URL: https://portal.noumena.cloud/${NPL_TENANT}/${NPL_APP}/services"
    exit 1
fi

# Derive Keycloak URL
KEYCLOAK_URL="${VITE_KEYCLOAK_URL:-https://keycloak-${NPL_TENANT}-${NPL_APP}.noumena.cloud}"
REALM="${VITE_KEYCLOAK_REALM:-${NPL_APP}}"

echo "📋 Configuration:"
echo "   Keycloak URL: $KEYCLOAK_URL"
echo "   Realm:        $REALM"
echo ""

# Get admin access token from master realm
echo "🔐 Authenticating as admin..."
# Use --data-urlencode to properly handle special characters in credentials
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=password" \
    --data-urlencode "client_id=admin-cli" \
    --data-urlencode "username=${KEYCLOAK_ADMIN_USER}" \
    --data-urlencode "password=${KEYCLOAK_ADMIN_PASSWORD}" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" == "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ Failed to authenticate as admin"
    echo "   Check your KEYCLOAK_ADMIN_USER and KEYCLOAK_ADMIN_PASSWORD"
    exit 1
fi

echo "✅ Authenticated"
echo ""

# Function to create a user
create_user() {
    local username=$1
    local email=$2
    local firstName=$3
    local password="${4:-password123456}"
    
    echo -n "   Creating user: $username... "
    
    # Check if user exists
    EXISTING=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/users?username=${username}" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq 'length')
    
    if [ "$EXISTING" -gt 0 ]; then
        echo "already exists ✓"
        return 0
    fi
    
    # Create user
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/users" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
            \"username\": \"${username}\",
            \"email\": \"${email}\",
            \"firstName\": \"${firstName}\",
            \"enabled\": true,
            \"emailVerified\": true,
            \"credentials\": [{
                \"type\": \"password\",
                \"value\": \"${password}\",
                \"temporary\": false
            }]
        }")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" == "201" ]; then
        echo "created ✓"
    else
        echo "failed (HTTP $HTTP_CODE)"
    fi
}

# Provision seed users (based on NPL dev mode defaults)
# Password updated to meet Noumena Cloud requirements: password123456
echo "👥 Creating seed users..."
echo ""

create_user "alice" "alice@example.com" "Alice"
create_user "bob" "bob@example.com" "Bob"
create_user "eve" "eve@example.org" "Eve"
create_user "carol" "carol@example.com" "Carol"
create_user "ivan" "ivan@example.com" "Ivan"
create_user "dave" "dave@example.com" "Dave"
create_user "frank" "frank@example.com" "Frank"
create_user "peggy" "peggy@example.com" "Peggy"
create_user "grace" "grace@example.com" "Grace"
create_user "heidi" "heidi@example.com" "Heidi"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ User provisioning complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 You can now log in with any of these users:"
echo "   Username: alice, bob, eve, carol, ivan, dave, frank, peggy, grace, heidi"
echo "   Password: password123456"
echo ""
echo "🔗 Keycloak Console: ${KEYCLOAK_URL}/admin/master/console"
