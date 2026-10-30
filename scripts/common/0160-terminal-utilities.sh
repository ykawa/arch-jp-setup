#!/bin/bash
# モダンな CLI ツール
# @group: モダン CLI ツール (bat / eza / fd / ripgrep / fzf など)
# @item: bat cat の代わり
# @item: eza ls の代わり
# @item: lsd ls の代わり（.bashrc が ls のエイリアスに使う）
# @item: fd find の代わり
# @item: ripgrep grep の代わり
# @item: fzf 絞り込み（.bashrc がキーバインドに使う）
# @item: peco 絞り込み（.bashrc の履歴検索が使う）
# @item: pv パイプの進捗表示
# @item: nkf 文字コード変換
# @item: grc コマンド出力の色付け
# @item: hexyl 16進ダンプ
# @item: fclones 重複ファイル検出
# @item: vivid LS_COLORS 生成
# @item: pastel 色の変換・表示
# @item: cfonts 大きな文字の表示
# @item: fastfetch システム情報の表示
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"

echo "==================================="
echo "  Terminal Utilities Installation"
echo "==================================="
echo ""

echo "Installing terminal utilities..."
install_selected_items "$0"

echo ""
echo "Terminal Utilities Installation completed!"
echo "==================================="
echo ""
