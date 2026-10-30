#!/bin/bash
# ファイラー（niri の Mod+E で起動するもの）
# @group: ファイラー
# @item: nautilus Nautilus（GNOME Files）
# @item: thunar Thunar @off
# @item: nemo Nemo @off
# @item: dolphin Dolphin @off
# @provides: nautilus filer nautilus org.gnome.Nautilus.desktop
# @provides: thunar filer thunar thunar.desktop
# @provides: nemo filer nemo nemo.desktop
# @provides: dolphin filer dolphin org.kde.dolphin.desktop
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"

echo "================================"
echo "  ファイラー"
echo "================================"
echo ""

echo "選択したファイラーをインストールしています..."
install_selected_items "$0"

echo ""
echo "ファイラーのインストールが完了しました"
echo "================================"
echo ""
