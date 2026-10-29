#!/bin/bash
# GNOME 外観設定
set -e

echo "================================"
echo "  GNOME Appearance Setup"
echo "================================"
echo ""

echo "Configuring GNOME appearance..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.desktop.interface monospace-font-name '源ノ角ゴシック Code JP 12'
gsettings set org.gnome.desktop.interface document-font-name '源ノ角ゴシック Code JP 12'
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false
echo ""

echo "================================"
echo "  Appearance setup completed!"
echo "================================"
echo ""
