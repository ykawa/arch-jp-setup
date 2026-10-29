#!/bin/bash
# ターミナルエミュレータとマルチプレクサ
# @group: ターミナル (foot / WezTerm / tmux / zellij)
set -e

echo "================================"
echo "  Terminal Apps Installation"
echo "================================"
echo ""

# foot + tmux: Omarchy-style terminal workspace (niri Mod+Alt+Return)
echo "Installing terminal emulators and multiplexers..."
paru -S --needed --noconfirm \
    foot \
    wezterm-nightly-bin \
    tmux \
    zellij \
    screen \
    || true

echo ""
echo "Terminal Apps Installation completed!"
echo "================================"
echo ""
