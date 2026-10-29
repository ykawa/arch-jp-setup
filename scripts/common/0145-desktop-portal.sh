#!/bin/bash
# xdg-desktop-portal と PipeWire（Wayland の画面共有・ファイル選択に必須）
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/link-config.sh"

echo "================================"
echo "  Desktop Portal Setup"
echo "================================"
echo ""

# xdg-desktop-portal-wlr: required for ScreenCast on wlroots-compatible compositors (niri, etc.)
echo "Installing desktop portals and PipeWire..."
paru -S --needed --noconfirm \
    xdg-desktop-portal \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-wlr \
    pipewire \
    wireplumber

# Deploy portal config for niri session
link_dotconfig "xdg-desktop-portal" "$REPO_ROOT"

echo ""
echo "Desktop Portal Setup completed!"
echo "================================"
echo ""
