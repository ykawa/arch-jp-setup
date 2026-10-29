#!/bin/bash
# This script installs essential fonts for development and Japanese support
set -e

echo "================================"
echo "  Fonts Installation Script"
echo "================================"
echo ""

# Get current user
CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"
echo ""

FONTS=(
    "otf-source-han-code-jp"
    "ttf-commit-mono"
    "ttf-cica"
    "ttf-jetbrains-mono-nerd"
    "ttf-mplus-nerd"
    "ttf-nerd-fonts-symbols"
    "ttf-font-awesome"
)

echo "Installing fonts..."
paru -S --needed --noconfirm "${FONTS[@]}" || true

# ttf-ms-win11-auto-japanese は初回パッケージアップデートとiso mountの関係で一度再起動をしないと
# インストールに失敗するときがあるので、一度実行してみて失敗したら再起動後に再実行するように表示する
if ! paru -S --needed --noconfirm "ttf-ms-win11-auto-japanese" || true; then
    echo "ttf-ms-win11-auto-japanese failed to install. Please reboot your system and run this script again."
    echo "Please reboot your system and run this script again."
    echo ""
    echo "bash $0"
    echo ""
    echo "================================"
fi

echo ""
echo "Refreshing font cache..."
fc-cache -fv

echo ""
echo "Font installation completed!"
echo ""
echo "================================"
