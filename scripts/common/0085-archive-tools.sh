#!/bin/bash
# アーカイブ・圧縮ツール
# @group: アーカイブ・圧縮ツール (7z / rar / lzh など)
set -e

echo "================================"
echo "  Archive Tools Installation"
echo "================================"
echo ""

# unrar conflicts with rar; remove it first if present
sudo pacman -Rns --noconfirm unrar 2>/dev/null || true

echo "Installing archive and compression tools..."
paru -S --needed --noconfirm \
    arj \
    bzip2 \
    cabextract \
    cpio \
    gzip \
    lhasa \
    libarchive \
    lrzip \
    lz4 \
    lzip \
    lzop \
    p7zip \
    rar \
    tar \
    unarchiver \
    xz \
    zpaq \
    zstd \
    || true

echo ""
echo "Archive Tools Installation completed!"
echo "================================"
echo ""
