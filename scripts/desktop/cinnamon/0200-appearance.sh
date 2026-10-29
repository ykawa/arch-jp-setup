#!/bin/bash
# Cinnamon 外観設定（キーボードリピート等）
set -e

echo "================================"
echo "  Cinnamon Appearance Setup"
echo "================================"
echo ""

echo "Installing GTK/Cinnamon styles (Mint-Y theme)..."
paru -S --needed --noconfirm cinnamon-styles-artwork
echo ""

echo "Configuring dark mode..."
gsettings set org.cinnamon.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.cinnamon.theme name 'Mint-Y-Dark'
echo ""

echo "Configuring keyboard repeat settings..."
gsettings set org.cinnamon.desktop.peripherals.keyboard repeat true
gsettings set org.cinnamon.desktop.peripherals.keyboard delay 180
gsettings set org.cinnamon.desktop.peripherals.keyboard repeat-interval 20
echo ""

echo "================================"
echo "  Appearance setup completed!"
echo "================================"
echo ""
