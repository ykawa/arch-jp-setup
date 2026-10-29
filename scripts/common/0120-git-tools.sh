#!/bin/bash
# Git 関連ツール
# @group: Git ツール (gh / tea / delta / difftastic / lazygit / hunk)
set -e

echo "================================"
echo "  Git Tools Installation"
echo "================================"
echo ""

# hunk-bin: terminal diff viewer (Omarchy uses `hunk diff --watch`)
echo "Installing git tools..."
paru -S --needed --noconfirm \
    github-cli \
    tea \
    lazygit \
    git-delta \
    difftastic \
    hunk-bin \
    || true

echo ""
echo "Git Tools Installation completed!"
echo "================================"
echo ""
