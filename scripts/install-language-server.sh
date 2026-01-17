#!/bin/bash
# Install NPL Language Server for syntax highlighting and diagnostics
# Downloads the pre-built binary from GitHub releases

set -e

LSP_VERSION="${NPL_LSP_VERSION:-2025.2.1}"
LSP_DIR="$HOME/.npl/lsp"
LSP_BINARY="$LSP_DIR/language-server"

echo "📦 Installing NPL Language Server v${LSP_VERSION}..."
echo ""

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        ARCH="x86_64"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

case "$OS" in
    linux)
        BINARY_NAME="language-server-linux-${ARCH}"
        ;;
    darwin)
        BINARY_NAME="language-server-macos-${ARCH}"
        ;;
    *)
        echo "❌ Unsupported OS: $OS"
        exit 1
        ;;
esac

DOWNLOAD_URL="https://github.com/NoumenaDigital/npl-language-server/releases/download/${LSP_VERSION}/${BINARY_NAME}"

echo "   Platform: ${OS}-${ARCH}"
echo "   Binary: ${BINARY_NAME}"
echo "   URL: ${DOWNLOAD_URL}"
echo ""

# Create directory
mkdir -p "$LSP_DIR"

# Check if already installed
if [ -f "$LSP_BINARY" ]; then
    echo "⚠️  Language server already installed at $LSP_BINARY"
    echo "   To reinstall, delete it first: rm $LSP_BINARY"
    exit 0
fi

# Download binary
echo "⬇️  Downloading..."
if command -v curl &> /dev/null; then
    curl -fsSL "$DOWNLOAD_URL" -o "$LSP_BINARY"
elif command -v wget &> /dev/null; then
    wget -q "$DOWNLOAD_URL" -O "$LSP_BINARY"
else
    echo "❌ Neither curl nor wget found"
    exit 1
fi

# Make executable
chmod +x "$LSP_BINARY"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ NPL Language Server installed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   Binary: $LSP_BINARY"
echo "   Version: $LSP_VERSION"
echo ""
echo "The language server provides:"
echo "   • Syntax highlighting for .npl files"
echo "   • Real-time error and warning detection"
echo "   • Code completion"
echo ""
