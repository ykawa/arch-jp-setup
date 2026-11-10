#!/bin/bash
# Git・CI 関連ツール
# @group: Git・CI ツール (gh / tea / lazygit / hunk / circleci)
# @item: github-cli GitHub CLI (gh)
# @item: tea Gitea CLI
# @item: lazygit Git の TUI
# @item: hunk-bin diff ビューア
# @item: circleci-cli-bin CircleCI CLI
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
