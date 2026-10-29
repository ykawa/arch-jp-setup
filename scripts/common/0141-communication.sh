#!/bin/bash
# コミュニケーションアプリ
# @group: コミュニケーション (Slack / Zoom)
set -e

echo "==================================="
echo "  Communication Apps Installation"
echo "==================================="
echo ""

echo "Installing Slack and Zoom..."
paru -S --needed --noconfirm \
    slack-desktop \
    zoom \
    || true

echo ""
echo "Communication Apps Installation completed!"
echo "==================================="
echo ""
