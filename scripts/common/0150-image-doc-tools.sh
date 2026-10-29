#!/bin/bash
# 画像・ドキュメント処理の CLI ツール
# @group: 画像・ドキュメント処理 CLI (ImageMagick / Ghostscript / Graphviz)
set -e

echo "======================================="
echo "  Image & Document Tools Installation"
echo "======================================="
echo ""

echo "Installing image and document tools..."
paru -S --needed --noconfirm \
    imagemagick \
    libheif \
    librsvg \
    libraw \
    libjxl \
    ghostscript \
    graphviz \
    silicon \
    || true

echo ""
echo "Image & Document Tools Installation completed!"
echo "======================================="
echo ""
