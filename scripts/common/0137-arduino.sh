#!/bin/bash
# Arduino 開発環境
# @group: Arduino 開発 (Arduino IDE)
set -e

echo "================================"
echo "  Arduino Installation"
echo "================================"
echo ""

echo "Installing Arduino IDE..."
paru -S --needed --noconfirm \
    arduino-ide-bin \
    arduino-language-server \
    || true

echo ""
echo "Arduino Installation completed!"
echo "================================"
echo ""
