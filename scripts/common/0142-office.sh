#!/bin/bash
# オフィススイート
# @group: オフィス (LibreOffice 日本語)
set -e

echo "================================"
echo "  Office Suite Installation"
echo "================================"
echo ""

echo "Installing LibreOffice..."
paru -S --needed --noconfirm \
    libreoffice-fresh \
    libreoffice-fresh-ja \
    || true

echo ""
echo "Office Suite Installation completed!"
echo "================================"
echo ""
