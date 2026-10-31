#!/bin/bash
# モダンな CLI ツール（選択画面は出さずに全部入れる）
set -e

echo "==================================="
echo "  Terminal Utilities Installation"
echo "==================================="
echo ""

echo "Installing terminal utilities..."
paru -S --needed --noconfirm \
    bat \
    eza \
    lsd \
    fd \
    ripgrep \
    fzf \
    skim \
    peco \
    zoxide \
    pv \
    nkf \
    grc \
    hexyl \
    fclones \
    vivid \
    pastel \
    cfonts \
    fastfetch \
    || true

echo ""
echo "Terminal Utilities Installation completed!"
echo "==================================="
echo ""
