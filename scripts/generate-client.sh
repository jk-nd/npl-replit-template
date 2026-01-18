#!/bin/bash
# Generate TypeScript client from NPL OpenAPI spec

set -e

echo "🔧 Generating TypeScript API client..."

# Source configuration files
if [ -f noumena.config ]; then
    source noumena.config
fi
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check required environment variables
if [ -z "$VITE_NPL_ENGINE_URL" ]; then
    # Try to derive from tenant/app
    if [ -n "$NPL_TENANT" ] && [ -n "$NPL_APP" ]; then
        export VITE_NPL_ENGINE_URL="https://engine-${NPL_TENANT}-${NPL_APP}.noumena.cloud"
    else
        echo "❌ Error: Cannot determine NPL Engine URL"
        echo "   Either set VITE_NPL_ENGINE_URL or both NPL_TENANT and NPL_APP"
        echo "   Run './scripts/setup-env.sh' first, or add secrets in Replit"
        exit 1
    fi
fi

echo "📥 Generating OpenAPI specs for all packages..."

# Generate OpenAPI specs for all packages
if ! npl openapi; then
    echo "❌ Failed to generate OpenAPI specs"
    echo ""
    echo "   Possible causes:"
    echo "   1. NPL CLI not installed - run './scripts/install-npl-cli.sh'"
    echo "   2. NPL code not compiled - check npl/src/main/"
    echo ""
    exit 1
fi

echo "📝 Processing OpenAPI specs..."

# Create output directory
mkdir -p ./frontend/src/generated

# Find all OpenAPI files and process them
OPENAPI_FILES=$(find ./openapi -name "*-openapi.yml" 2>/dev/null)

if [ -z "$OPENAPI_FILES" ]; then
    echo "❌ No OpenAPI files found in ./openapi/"
    echo "   Make sure NPL packages are compiled"
    exit 1
fi

# Process each OpenAPI file
for OPENAPI_FILE in $OPENAPI_FILES; do
    # Extract package name from filename (e.g., demo-openapi.yml -> demo)
    PACKAGE_NAME=$(basename "$OPENAPI_FILE" | sed 's/-openapi\.yml$//')
    
    echo "  📦 Processing package: $PACKAGE_NAME"
    
    # Create package-specific directory
    PACKAGE_DIR="./frontend/src/generated/$PACKAGE_NAME"
    mkdir -p "$PACKAGE_DIR"
    
    # Replace localhost with actual engine URL and keep as YAML
    sed "s|http://localhost:12000|${VITE_NPL_ENGINE_URL}|g" "$OPENAPI_FILE" > "$PACKAGE_DIR/openapi.yml"
    
    # Generate TypeScript types from YAML
    cd frontend && npx openapi-typescript "./src/generated/$PACKAGE_NAME/openapi.yml" -o "./src/generated/$PACKAGE_NAME/api-types.ts" && cd ..
    
    echo "  ✅ Generated client for $PACKAGE_NAME"
done

echo "✅ API client generation complete!"
echo ""
echo "Generated files in frontend/src/generated/:"
for OPENAPI_FILE in $(find ./openapi -name "*-openapi.yml" 2>/dev/null); do
    PACKAGE_NAME=$(basename "$OPENAPI_FILE" | sed 's/-openapi\.yml$//')
    echo "  📦 $PACKAGE_NAME/"
    echo "    - openapi.yml"
    echo "    - api-types.ts"
done
echo ""
echo "Import types in your code:"
echo "  import type { paths, components } from './generated/{package}/api-types';"
