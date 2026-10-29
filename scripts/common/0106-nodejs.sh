#!/bin/bash
# Node.js と npm
# @group: Node.js / npm
set -e

echo "================================"
echo "  Node.js Installation"
echo "================================"
echo ""

echo "Installing Node.js and npm..."
paru -S --needed --noconfirm \
    nodejs \
    npm \
    || true

echo ""
echo "Node.js Installation completed!"
echo "================================"
echo ""
