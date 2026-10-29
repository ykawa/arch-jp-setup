#!/bin/bash
# クリップボードマネージャのセットアップ (cliphist + wl-clip-persist)
set -e

echo "================================"
echo "  Clipboard Manager Setup"
echo "================================"
echo ""

echo "Installing clipboard manager packages..."
paru -S --needed --noconfirm cliphist wl-clip-persist wl-clipboard

echo "Clipboard manager packages installed!"
echo ""
echo "Note: autostart entries and keybind are configured in niri config.kdl"
echo "  - wl-clip-persist: clipboard persistence across app closures"
echo "  - cliphist: clipboard history daemon (single watcher, all MIME types)"
echo "  - Keybind: Alt+Ctrl+H to open clipboard history"
echo ""
echo "================================"
echo "  Clipboard Manager setup completed!"
echo "================================"
echo ""
