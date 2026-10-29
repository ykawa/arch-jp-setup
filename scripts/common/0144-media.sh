#!/bin/bash
# 動画プレーヤー・画像ビューア・画像編集（Wayland ネイティブ）
# @group: メディア (mpv / imv / Pinta)
set -e

echo "================================"
echo "  Media Apps Installation"
echo "================================"
echo ""

echo "Installing media apps..."
paru -S --needed --noconfirm \
    mpv \
    imv \
    pinta \
    || true

echo ""
echo "Media Apps Installation completed!"
echo "================================"
echo ""
