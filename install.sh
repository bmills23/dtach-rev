#!/bin/sh
# dtach-rev installer — downloads pre-built binary from GitHub Releases
# Usage: curl -sSL https://raw.githubusercontent.com/bmills23/dtach-rev/master/install.sh | sh
set -e

REPO="bmills23/dtach-rev"
INSTALL_DIR="/usr/local/bin"
BINARY="dtach-rev"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  linux)  OS_TAG="linux" ;;
  darwin) OS_TAG="macos" ;;
  *)
    echo "Error: Unsupported OS '$OS'. Build from source instead:"
    echo "  git clone https://github.com/$REPO.git && cd dtach-rev && ./configure && make && sudo make install"
    exit 1
    ;;
esac

case "$ARCH" in
  x86_64|amd64)  ARCH_TAG="x86_64" ;;
  aarch64|arm64) ARCH_TAG="arm64" ;;
  *)
    echo "Error: Unsupported architecture '$ARCH'. Build from source instead:"
    echo "  git clone https://github.com/$REPO.git && cd dtach-rev && ./configure && make && sudo make install"
    exit 1
    ;;
esac

ASSET="dtach-rev-${OS_TAG}-${ARCH_TAG}"
LATEST_URL="https://github.com/$REPO/releases/latest/download/$ASSET"

echo "dtach-rev installer"
echo "  OS:   $OS ($OS_TAG)"
echo "  Arch: $ARCH ($ARCH_TAG)"
echo "  URL:  $LATEST_URL"
echo ""

# Download
TMP=$(mktemp)
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$LATEST_URL" -o "$TMP" || {
    echo "Error: Download failed. No release found for $ASSET."
    echo "Build from source instead:"
    echo "  git clone https://github.com/$REPO.git && cd dtach-rev && ./configure && make && sudo make install"
    rm -f "$TMP"
    exit 1
  }
elif command -v wget >/dev/null 2>&1; then
  wget -q "$LATEST_URL" -O "$TMP" || {
    echo "Error: Download failed."
    rm -f "$TMP"
    exit 1
  }
else
  echo "Error: Neither curl nor wget found."
  exit 1
fi

chmod +x "$TMP"

# Install — try without sudo first, fall back to sudo
if [ -w "$INSTALL_DIR" ]; then
  mv "$TMP" "$INSTALL_DIR/$BINARY"
else
  echo "Installing to $INSTALL_DIR (requires sudo)..."
  sudo mv "$TMP" "$INSTALL_DIR/$BINARY"
fi

# Create 'dtach' symlink so TerminaLLM can find it
if [ ! -e "$INSTALL_DIR/dtach" ]; then
  if [ -w "$INSTALL_DIR" ]; then
    ln -sf "$INSTALL_DIR/$BINARY" "$INSTALL_DIR/dtach"
  else
    sudo ln -sf "$INSTALL_DIR/$BINARY" "$INSTALL_DIR/dtach"
  fi
  echo "Created symlink: dtach -> dtach-rev"
fi

echo ""
echo "Installed: $(command -v $BINARY || echo "$INSTALL_DIR/$BINARY")"
$INSTALL_DIR/$BINARY --help 2>&1 | head -1
echo ""
echo "Done! Reconnect from TerminaLLM to activate session persistence."
