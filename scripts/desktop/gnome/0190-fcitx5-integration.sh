#!/bin/bash
# Fcitx5 GNOME統合（GNOME固有）
set -e

echo "================================"
echo "  Fcitx5 GNOME Integration"
echo "================================"
echo ""

# kimpanel拡張機能のインストール
echo "Installing GNOME extensions for fcitx5..."
yay -S --noconfirm --needed \
    gnome-browser-connector \
    gnome-shell-extension-installer \
    gnome-shell-extension-kimpanel-git
echo ""

# kimpanel拡張機能を有効化
echo "Enabling Kimpanel extension..."
gnome-extensions enable kimpanel@kde.org
echo ""

# GNOME Shell再起動
echo "Restarting GNOME Shell..."
gnome-shell --replace &
sleep 2
echo ""

# 再度有効化（確実にするため）
gnome-extensions enable kimpanel@kde.org
echo ""

# GNOME固有のgsettings設定
echo "Configuring GNOME settings for fcitx5..."
gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "{'Gtk/IMModule':<'fcitx'>}"
echo ""

echo "================================"
echo "  Fcitx5 GNOME integration completed!"
echo "  Please reboot for all changes to take effect."
echo "================================"
echo ""
