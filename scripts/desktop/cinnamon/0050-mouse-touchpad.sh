#!/bin/bash
# Cinnamon マウス/タッチパッド設定
set -e

echo "================================"
echo "  Cinnamon Mouse/Touchpad Setup"
echo "================================"
echo ""

echo "Configuring Cinnamon mouse settings..."
gsettings set org.cinnamon.desktop.peripherals.mouse speed 0.8
gsettings set org.cinnamon.desktop.peripherals.mouse natural-scroll false
echo ""

echo "Configuring Cinnamon touchpad settings..."
gsettings set org.cinnamon.desktop.peripherals.touchpad speed 0.7
gsettings set org.cinnamon.desktop.peripherals.touchpad natural-scroll true
gsettings set org.cinnamon.desktop.peripherals.touchpad tap-to-click true
gsettings set org.cinnamon.desktop.peripherals.touchpad two-finger-scrolling-enabled true
gsettings set org.cinnamon.desktop.peripherals.touchpad disable-while-typing true
echo ""

echo "================================"
echo "  Mouse/Touchpad setup completed!"
echo "================================"
echo ""
