#!/bin/bash
# Rust ツールチェーン（rustup）
# @group: Rust (rustup)
set -e

echo "================================"
echo "  Rust Toolchain Installation"
echo "================================"
echo ""

echo "Installing rustup..."
paru -S --needed --noconfirm \
    rustup

rustup default stable

echo ""
echo "Rust Toolchain Installation completed!"
echo "================================"
echo ""
