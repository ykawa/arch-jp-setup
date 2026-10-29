#!/bin/bash
# 小物の GUI ユーティリティ
# @group: GUI ユーティリティ (LocalSend / galculator / wev)
set -e

echo "================================"
echo "  GUI Utilities Installation"
echo "================================"
echo ""

echo "Installing GUI utilities..."
paru -S --needed --noconfirm \
    localsend \
    galculator \
    wev \
    || true

echo ""
echo "GUI Utilities Installation completed!"
echo "================================"
echo ""
