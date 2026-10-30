#!/bin/bash
# Web ブラウザ
# @group: ブラウザ
# @item: google-chrome Google Chrome
# @item: firefox Firefox @off
# @item: chromium Chromium @off
# @provides: google-chrome browser google-chrome-stable google-chrome.desktop
# @provides: firefox browser firefox firefox.desktop
# @provides: chromium browser chromium chromium.desktop
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"

echo "================================"
echo "  ブラウザ"
echo "================================"
echo ""

echo "選択したブラウザをインストールしています..."
install_selected_items "$0"

echo ""
echo "ブラウザのインストールが完了しました"
echo "================================"
echo ""
