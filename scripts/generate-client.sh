#!/bin/bash
# Generate TypeScript client from NPL OpenAPI spec

set -e

echo "🔧 Generating TypeScript API client..."

# Source .env if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check required environment variables
if [ -z "$VITE_NPL_ENGINE_URL" ]; then
    # Try to derive from tenant/app
    if [ -n "$NPL_TENANT" ] && [ -n "$NPL_APP_NAME" ]; then
        export VITE_NPL_ENGINE_URL="https://engine-${NPL_TENANT}-${NPL_APP_NAME}.noumena.cloud"
    else
        echo "❌ Error: Cannot determine NPL Engine URL"
        echo "   Either set VITE_NPL_ENGINE_URL or both NPL_TENANT and NPL_APP_NAME"
        echo "   Run './scripts/setup-env.sh' first, or add secrets in Replit"
        exit 1
    fi
fi

# Package name - defaults to 'demo' if not set
NPL_PACKAGE="${NPL_PACKAGE:-demo}"

# OpenAPI endpoint (no auth required for this endpoint)
OPENAPI_URL="${VITE_NPL_ENGINE_URL}/npl/${NPL_PACKAGE}/-/openapi.json"

echo "📥 Fetching OpenAPI spec from: $OPENAPI_URL"

# Create output directory
mkdir -p ./src/generated

# Fetch OpenAPI spec
if ! curl -sf "$OPENAPI_URL" > ./src/generated/openapi.json; then
    echo "❌ Failed to fetch OpenAPI spec"
    echo ""
    echo "   Possible causes:"
    echo "   1. NPL code not deployed yet - run 'Deploy to Noumena Cloud' first"
    echo "   2. Wrong package name - check NPL_PACKAGE (currently: $NPL_PACKAGE)"
    echo "   3. Wrong tenant/app - check your Secrets"
    echo ""
    echo "   Tried URL: $OPENAPI_URL"
    exit 1
fi

echo "📝 Generating TypeScript types..."

# Generate TypeScript types using openapi-typescript
npx openapi-typescript ./src/generated/openapi.json -o ./src/generated/api-types.ts

echo "✅ API client generated!"
echo ""
echo "Generated files:"
echo "  - src/generated/openapi.json"
echo "  - src/generated/api-types.ts"
echo ""
echo "Import types in your code:"
echo "  import type { paths, components } from './generated/api-types';"
