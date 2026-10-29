#!/bin/bash
# 画面録画ツール（Wayland）
# @group: 画面録画 (Kooha / wf-recorder)
set -e

echo "================================="
echo "  Screencast Tools Installation"
echo "================================="
echo ""

echo "Installing screen recorders..."
paru -S --needed --noconfirm \
    kooha \
    wf-recorder \
    || true

echo ""
echo "Screencast Tools Installation completed!"
echo "================================="
echo ""
