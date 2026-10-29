#!/bin/bash
# Zed エディタのインストールと設定ファイル配置（シンボリックリンク）
# @group: Zed エディタ
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/link-config.sh"
source "$REPO_ROOT/lib/install-copy.sh"
source "$REPO_ROOT/lib/local-settings.sh"

echo "================================"
echo "  Zed Editor Setup"
echo "================================"
echo ""

echo "Installing Zed..."
paru -S --needed --noconfirm \
    zed \
    || true

# PC ごとの検索パターンは INSTALL_DIR のコピーにだけ書き込む（git の作業ディレクトリは触らない）
if [ "$REPO_ROOT" = "$INSTALL_DIR" ]; then
    apply_zed_file_scan_inclusions "$REPO_ROOT/dot.config/zed/settings.json"
fi

link_dotconfig "zed" "$REPO_ROOT"

echo ""
echo "Zed Editor Setup completed!"
echo "================================"
echo ""
