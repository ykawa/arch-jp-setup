#!/bin/bash
# Noctalia v5 desktop shell setup (replaces waybar)
# https://noctalia.dev / https://github.com/noctalia-dev/noctalia
#
# v5 is the native C++ rewrite shipped as `noctalia` in the Arch extra repository.
# Do not install `noctalia-shell` / `noctalia-qs`: those are the end-of-life
# Quickshell-based v4 packages.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$REPO_ROOT/lib/link-config.sh"
source "$REPO_ROOT/lib/install-copy.sh"
source "$REPO_ROOT/lib/local-settings.sh"

echo "================================"
echo "  Noctalia Desktop Shell Setup"
echo "================================"
echo ""

echo "Installing Noctalia and optional dependencies..."
# upower: battery widget / power-profiles-daemon: power profile toggle
paru -S --needed --noconfirm \
    noctalia \
    upower \
    power-profiles-daemon \
    || true

echo ""
echo "Preparing avatar image..."
# config.toml は ~/.local/share/arch-jp-setup/images/avatar.png を参照する
fetch_avatar_image "$INSTALL_DIR"

echo ""
echo "Linking Noctalia configuration..."
link_dotconfig "noctalia" "$REPO_ROOT"

echo ""
echo "================================"
echo "  Noctalia setup completed!"
echo "================================"
echo ""
echo "Noctalia will start automatically with niri."
echo "To start manually: noctalia"
echo "Validate the config: noctalia config validate"
echo "External monitor brightness needs ddcutil (optional)."
echo ""
