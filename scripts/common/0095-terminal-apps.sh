#!/bin/bash
# ターミナルエミュレータとマルチプレクサ
# @group: ターミナル (端末エミュレータ / マルチプレクサ)
# @item: alacritty 端末（niri の Mod+Return）
# @item: foot 端末（niri の Mod+Shift+Return / Mod+Alt+Return / Claude Code / Neovim）
# @item: wezterm-nightly-bin 端末 WezTerm（GNOME / Cinnamon のショートカット）
# @item: kitty 端末 @off
# @item: ghostty 端末 @off
# @item: tmux マルチプレクサ（niri の Mod+Alt+Return）
# @item: zellij マルチプレクサ
# @item: screen マルチプレクサ
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"

echo "================================"
echo "  Terminal Apps Installation"
echo "================================"
echo ""

# foot + tmux: Omarchy-style terminal workspace (niri Mod+Alt+Return)
echo "Installing terminal emulators and multiplexers..."
install_selected_items "$0"

echo ""
echo "Terminal Apps Installation completed!"
echo "================================"
echo ""
