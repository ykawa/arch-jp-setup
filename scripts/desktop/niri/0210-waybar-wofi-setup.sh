#!/bin/bash
# waybar と wofi の設定ファイル配置（シンボリックリンク）
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$REPO_ROOT/lib/link-config.sh"

echo "================================"
echo "  Waybar & Wofi Config Setup"
echo "================================"
echo ""

link_dotconfig "waybar" "$REPO_ROOT"
link_dotconfig "wofi" "$REPO_ROOT"

echo ""
echo "================================"
echo "  Waybar & Wofi setup completed!"
echo "================================"
echo ""
