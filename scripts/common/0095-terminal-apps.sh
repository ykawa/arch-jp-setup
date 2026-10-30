#!/bin/bash
# ターミナルエミュレータとマルチプレクサ
# @group: ターミナル (端末エミュレータ / マルチプレクサ)
# @item: alacritty 端末 Alacritty（zellij も入る）
# @item: foot 端末 foot（tmux も入る）
# @item: wezterm-nightly-bin 端末 WezTerm
# @item: kitty 端末 kitty @off
# @item: ghostty 端末 Ghostty @off
# @item: zellij マルチプレクサ（alacritty を選べば自動で入る） @off
# @item: tmux マルチプレクサ（foot を選べば自動で入る） @off
# @item: screen マルチプレクサ @off
# @bundle: alacritty zellij
# @bundle: foot tmux
# @provides: alacritty terminal alacritty Alacritty.desktop
# @provides: foot terminal foot foot.desktop
# @provides: wezterm-nightly-bin terminal wezterm org.wezfurlong.wezterm.desktop
# @provides: kitty terminal kitty kitty.desktop
# @provides: ghostty terminal ghostty com.mitchellh.ghostty.desktop
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"

echo "================================"
echo "  Terminal Apps Installation"
echo "================================"
echo ""

echo "Installing terminal emulators and multiplexers..."
install_selected_items "$0"

echo ""
echo "Terminal Apps Installation completed!"
echo "================================"
echo ""
