#!/bin/bash
# モダンな CLI ツール
# @group: モダン CLI ツール (bat / eza / fd / ripgrep / fzf など)
set -e

echo "==================================="
echo "  Terminal Utilities Installation"
echo "==================================="
echo ""

echo "Installing terminal utilities..."
paru -S --needed --noconfirm \
    bat \
    eza \
    fd \
    ripgrep \
    fzf \
    lsd \
    peco \
    pv \
    nkf \
    grc \
    hexyl \
    fclones \
    vivid \
    pastel \
    cfonts \
    gum \
    fastfetch \
    || true

echo ""
echo "Terminal Utilities Installation completed!"
echo "==================================="
echo ""
