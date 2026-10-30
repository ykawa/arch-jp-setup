#!/bin/bash
# 画面録画ツール（Wayland）
# @group: 画面録画 (Kooha / wf-recorder)
# @item: kooha GUI
# @item: wf-recorder CLI
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"

echo "================================="
echo "  Screencast Tools Installation"
echo "================================="
echo ""

echo "Installing screen recorders..."
install_selected_items "$0"

echo ""
echo "Screencast Tools Installation completed!"
echo "================================="
echo ""
