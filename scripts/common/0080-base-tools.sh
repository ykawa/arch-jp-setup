#!/bin/bash
# 全環境で必須の基本ツール（ビルド・Python・クリップボード・ファームウェア更新）
set -e

echo "================================"
echo "  Base Tools Installation"
echo "================================"
echo ""

echo "Installing base tools..."
paru -S --needed --noconfirm \
    cmake \
    curl \
    gcc \
    git \
    make \
    python \
    python-pip \
    python-pipx \
    tree \
    unzip \
    zip \
    wget \
    htop \
    jq \
    vim \
    fwupd \
    wl-clipboard \
    || true

echo ""
echo "Base Tools Installation completed!"
echo "================================"
echo ""
