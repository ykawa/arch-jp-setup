#!/bin/bash
# JetBrains Toolbox（IDE はここから入れる）
# @group: JetBrains Toolbox
set -e

echo "=================================="
echo "  JetBrains Toolbox Installation"
echo "=================================="
echo ""

echo "Installing JetBrains Toolbox..."
paru -S --needed --noconfirm \
    jetbrains-toolbox \
    || true

echo ""
echo "JetBrains Toolbox Installation completed!"
echo "=================================="
echo ""
