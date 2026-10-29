#!/bin/bash
# テーマ・アイコン・カーソルのインストール（全デスクトップ環境共通）
set -e

echo "================================"
echo "  Themes / Icons / Cursors"
echo "================================"
echo ""

echo "Installing icon theme..."
paru -S --needed --noconfirm papirus-icon-theme

echo "Installing cursor theme..."
paru -S --needed --noconfirm bibata-cursor-theme

echo "Installing Tokyo Night GTK theme..."
paru -S --needed --noconfirm tokyonight-gtk-theme-git

echo ""
echo "Themes installation completed!"
echo ""
