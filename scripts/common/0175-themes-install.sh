#!/bin/bash
# テーマ・アイコン・カーソルのインストール（全デスクトップ環境共通）
# @group: テーマ・アイコン・カーソル
# @item: tokyonight-gtk-theme-git GTK テーマ Tokyonight（gtk-3.0 / gtk-4.0 / xsettingsd の設定が使う）
# @item: gtk-theme-numix-sx GTK テーマ Numix-SX（niri の gsettings が使う）
# @item: mint-l-theme GTK テーマ Mint-L @off
# @item: papirus-icon-theme アイコン Papirus（GTK の設定が使う）
# @item: mint-l-icons アイコン Mint-L @off
# @item: bibata-cursor-theme カーソル Bibata（GTK の設定と niri の gsettings が使う）
# @item: capitaine-cursors カーソル Capitaine @off
# @item: kvantum Qt アプリのテーマエンジン @off
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"

echo "================================"
echo "  テーマ・アイコン・カーソル"
echo "================================"
echo ""

echo "選択したテーマをインストールしています..."
install_selected_items "$0"

echo ""
echo "テーマのインストールが完了しました"
echo ""
