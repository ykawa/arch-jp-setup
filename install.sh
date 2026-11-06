#!/bin/bash
# One-liner installer for arch-jp-setup
# Usage: curl -fsSL https://raw.githubusercontent.com/ykawa/arch-jp-setup/main/install.sh | bash
# Alternative: wget -qO- https://raw.githubusercontent.com/ykawa/arch-jp-setup/main/install.sh | bash
set -e

BOOT_URL="https://raw.githubusercontent.com/ykawa/arch-jp-setup/main/boot.sh"

echo "================================"
echo "  arch/manjaro/cachyos Japanese Setup"
echo "  One-liner Installer"
echo "================================"
echo ""

# Check for download tools
if command -v curl &>/dev/null; then
    DOWNLOADER="curl -fsSL"
    echo "Using curl for download..."
elif command -v wget &>/dev/null; then
    DOWNLOADER="wget -qO-"
    echo "Using wget for download..."
else
    echo "Error: Neither curl nor wget is available."
    echo "Please install one of them:"
    echo "  sudo pacman -S curl"
    echo "  sudo pacman -S wget"
    exit 1
fi

echo "Downloading and executing boot script..."
echo "Source: $BOOT_URL"
echo ""

# Download and execute the boot script
exec bash <($DOWNLOADER "$BOOT_URL")
