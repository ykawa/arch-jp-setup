#!/bin/bash
# ネットワーク・クラウド同期ツール
# @group: ネットワーク・同期 (rclone / OneDrive / ngrok / arp-scan)
# @item: rclone クラウドストレージ同期（OneDrive も可）
# @item: onedrive-abraunegg OneDrive 専用の同期クライアント
# @item: ngrok ローカルのポートを公開
# @item: arp-scan LAN 内の機器を探す
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"

echo "================================"
echo "  Network Tools Installation"
echo "================================"
echo ""

echo "Installing network and sync tools..."
install_selected_items "$0"

echo ""
echo "Network Tools Installation completed!"
echo "================================"
echo ""
