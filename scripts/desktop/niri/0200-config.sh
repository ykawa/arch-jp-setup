#!/bin/bash
# niri 設定ファイル配置（シンボリックリンク）
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$REPO_ROOT/lib/link-config.sh"

echo "================================"
echo "  niri Configuration Setup"
echo "================================"
echo ""

# X11 専用アプリ用（niri は PATH 上の xwayland-satellite を自動起動する）
echo "Installing xwayland-satellite..."
paru -S --needed --noconfirm xwayland-satellite

link_dotconfig "niri" "$REPO_ROOT"

echo ""
echo "================================"
echo "  niri configuration completed!"
echo "  Reload config:"
echo "  niri msg action load-config-file"
echo "================================"
echo ""
