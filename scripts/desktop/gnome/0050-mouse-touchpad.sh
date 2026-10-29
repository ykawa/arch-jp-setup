#!/bin/bash
# GNOME マウス/タッチパッド設定
set -e

echo "================================"
echo "  GNOME Mouse/Touchpad Setup"
echo "================================"
echo ""

echo "Configuring GNOME mouse settings..."
gsettings set org.gnome.desktop.peripherals.mouse speed 0.8
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'adaptive'
echo ""

echo "Configuring GNOME touchpad settings..."
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.7
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
echo ""

echo "================================"
echo "  Mouse/Touchpad setup completed!"
echo "================================"
echo ""
