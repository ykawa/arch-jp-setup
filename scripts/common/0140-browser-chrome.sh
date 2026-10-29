#!/bin/bash
# Google Chrome
# @group: Google Chrome
set -e

echo "================================"
echo "  Google Chrome Installation"
echo "================================"
echo ""

echo "Installing Google Chrome..."
paru -S --needed --noconfirm \
    google-chrome \
    || true

echo ""
echo "Google Chrome Installation completed!"
echo "================================"
echo ""
