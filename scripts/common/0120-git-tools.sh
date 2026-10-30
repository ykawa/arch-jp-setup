#!/bin/bash
# Git 関連ツール
# @group: Git ツール (gh / tea / delta / difftastic / lazygit / hunk)
# @item: github-cli GitHub CLI (gh)
# @item: tea Gitea CLI
# @item: lazygit Git の TUI
# @item: git-delta diff 表示（git の pager に設定済み）
# @item: difftastic 構文を見る diff（git の difftool に設定済み）
# @item: hunk-bin diff ビューア
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"

echo "================================"
echo "  Git Tools Installation"
echo "================================"
echo ""

# hunk-bin: terminal diff viewer (Omarchy uses `hunk diff --watch`)
echo "Installing git tools..."
install_selected_items "$0"

echo ""
echo "Git Tools Installation completed!"
echo "================================"
echo ""
