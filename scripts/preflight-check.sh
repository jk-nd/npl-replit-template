#!/bin/bash
# Pre-flight checks before development
# Run this to validate your environment is set up correctly

echo "🔍 Running pre-flight checks..."
echo ""

ERRORS=0

# Check NPL CLI
if ! command -v npl &> /dev/null && [ ! -f "$HOME/.npl/bin/npl" ]; then
    echo "❌ NPL CLI not found"
    echo "   Run: make install"
    ERRORS=$((ERRORS + 1))
else
    NPL_VERSION=$(npl --version 2>/dev/null || $HOME/.npl/bin/npl --version 2>/dev/null || echo 'unknown')
    echo "✅ NPL CLI installed: $NPL_VERSION"
fi

# Check login status
export PATH="$HOME/.npl/bin:$PATH"
if npl cloud status &>/dev/null; then
    echo "✅ Logged in to Noumena Cloud"
else
    echo "⚠️  Not logged in to Noumena Cloud"
    echo "   Run: make login"
fi

# Check .env
if [ -f .env ]; then
    echo "✅ .env file exists"
    
    # Check required variables
    source .env 2>/dev/null
    if [ -z "$VITE_NPL_ENGINE_URL" ]; then
        echo "   ⚠️  VITE_NPL_ENGINE_URL not set in .env"
    fi
    if [ -z "$VITE_KEYCLOAK_URL" ]; then
        echo "   ⚠️  VITE_KEYCLOAK_URL not set in .env"
    fi
else
    echo "⚠️  .env file missing"
    echo "   Run: make env"
fi

# Check environment variables
if [ -z "$NPL_TENANT" ]; then
    echo "⚠️  NPL_TENANT not set"
    echo "   Add it in Replit's Secrets tab or export it"
else
    echo "✅ NPL_TENANT: $NPL_TENANT"
fi

if [ -z "$NPL_APP" ]; then
    echo "⚠️  NPL_APP not set"
    echo "   Add it in Replit's Secrets tab or export it"
else
    echo "✅ NPL_APP: $NPL_APP"
fi

# Check node_modules
if [ -d "frontend/node_modules" ]; then
    echo "✅ Frontend dependencies installed"
else
    echo "⚠️  Frontend dependencies not installed"
    echo "   Run: cd frontend && npm install"
fi

# Check if generated API client exists
if [ -d "frontend/src/generated" ]; then
    echo "✅ API client generated"
else
    echo "⚠️  API client not generated"
    echo "   Run: make client (after deploying NPL)"
fi

echo ""
if [ $ERRORS -gt 0 ]; then
    echo "❌ Pre-flight check failed with $ERRORS error(s)"
    exit 1
else
    echo "🏁 Pre-flight check complete!"
fi
