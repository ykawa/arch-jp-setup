#!/bin/bash
# Markdown エディタ Typora
# @group: Typora (Markdown エディタ)
set -e

echo "================================"
echo "  Typora Installation"
echo "================================"
echo ""

echo "Installing Typora..."
paru -S --needed --noconfirm \
    typora \
    || true

echo ""
echo "Typora Installation completed!"
echo "================================"
echo ""
