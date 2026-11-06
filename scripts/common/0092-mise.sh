#!/bin/bash
# mise（開発ツールのバージョン管理）
# @group: mise (開発ツールのバージョン管理)
set -e

echo "================================"
echo "  mise Installation"
echo "================================"
echo ""

echo "Installing mise..."
paru -S --needed --noconfirm mise

# ~/.mise.toml は 0050-link-configs.sh がリンクする。グローバル設定ではないので信頼が必要
if [ -e "$HOME/.mise.toml" ]; then
    mise trust "$HOME/.mise.toml"
fi

if [ ! -e "$HOME/.tool-versions" ]; then
    echo "Creating ~/.tool-versions..."
    echo "node lts" >"$HOME/.tool-versions"
fi

echo ""
echo "mise installation completed!"
echo "  Install tools: mise install"
echo "================================"
echo ""
