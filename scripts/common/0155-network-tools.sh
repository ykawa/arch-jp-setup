#!/bin/bash
# ネットワーク・クラウド同期ツール
# @group: ネットワーク・同期 (rclone / OneDrive / ngrok / arp-scan)
set -e

echo "================================"
echo "  Network Tools Installation"
echo "================================"
echo ""

echo "Installing network and sync tools..."
paru -S --needed --noconfirm \
    rclone \
    onedrive-abraunegg \
    ngrok \
    arp-scan \
    || true

echo ""
echo "Network Tools Installation completed!"
echo "================================"
echo ""
