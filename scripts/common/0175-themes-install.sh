#!/bin/bash
# テーマ・アイコン・カーソルのインストール（全デスクトップ環境共通）
# @group: テーマ・アイコン・カーソル
# @item: tokyonight-gtk-theme-git GTK テーマ Tokyonight
# @item: gtk-theme-numix-sx GTK テーマ Numix-SX
# @item: mint-l-theme GTK テーマ Mint-L @off
# @item: papirus-icon-theme アイコン Papirus
# @item: mint-l-icons アイコン Mint-L @off
# @item: bibata-cursor-theme カーソル Bibata
# @item: capitaine-cursors カーソル Capitaine @off
# @item: kvantum Qt アプリのテーマエンジン @off
# @provides: tokyonight-gtk-theme-git gtk Tokyonight-Dark
# @provides: gtk-theme-numix-sx gtk Numix-SX-FullDark
# @provides: mint-l-theme gtk Mint-L-Dark-Teal
# @provides: papirus-icon-theme icon Papirus-Dark
# @provides: mint-l-icons icon Mint-L
# @provides: bibata-cursor-theme cursor Bibata-Modern-Classic
# @provides: capitaine-cursors cursor capitaine-cursors
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"
source "$REPO_ROOT/lib/install-copy.sh"
source "$REPO_ROOT/lib/defaults.sh"

echo "================================"
echo "  テーマ・アイコン・カーソル"
echo "================================"
echo ""

echo "選択したテーマをインストールしています..."
install_selected_items "$0"

# 入ったテーマを GTK の設定へ反映する（INSTALL_DIR のコピーにだけ書く）
if [ "$REPO_ROOT" = "$INSTALL_DIR" ]; then
    echo "テーマの設定を反映しています..."
    apply_theme_settings "$REPO_ROOT"
fi

echo ""
echo "テーマのインストールが完了しました"
echo ""
