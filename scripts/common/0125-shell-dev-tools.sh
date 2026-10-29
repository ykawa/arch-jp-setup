#!/bin/bash
# シェルスクリプト開発ツール
# @group: シェルスクリプト開発 (shellcheck / shfmt)
set -e

echo "================================"
echo "  Shell Dev Tools Installation"
echo "================================"
echo ""

echo "Installing shellcheck and shfmt..."
paru -S --needed --noconfirm \
    shellcheck \
    shfmt \
    || true

echo ""
echo "Shell Dev Tools Installation completed!"
echo "================================"
echo ""
