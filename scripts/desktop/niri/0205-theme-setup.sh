#!/bin/bash
# niri テーマ・アイコン・カーソル・フォント設定
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$REPO_ROOT/lib/link-config.sh"
source "$REPO_ROOT/lib/defaults.sh"

echo "================================"
echo "  Theme Setup for niri"
echo "================================"
echo ""

# テーマのパッケージは scripts/common/0175-themes-install.sh で選んで入れる。
# 入っていないテーマを指定しても GTK は既定（Adwaita）で表示する。

# ── 設定ファイルのリンク ───────────────────────────────────

echo "[1/2] Linking config files..."
link_dotconfig "gtk-3.0" "$REPO_ROOT"
link_dotconfig "gtk-4.0" "$REPO_ROOT"

echo ""

# ── gsettings（GNOME/GTK アプリ共通） ──────────────────────

echo "[2/2] Applying gsettings..."

# GTK の設定ファイルと同じ値（入っていないテーマは Adwaita）
GTK_THEME_NAME=$(theme_value gtk)
ICON_THEME_NAME=$(theme_value icon)
CURSOR_THEME_NAME=$(theme_value cursor)
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME"
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME_NAME"
gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME_NAME"
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface font-name 'Meiryo UI 11'
gsettings set org.gnome.desktop.interface document-font-name 'Meiryo UI 11'
gsettings set org.gnome.desktop.interface monospace-font-name '源ノ角ゴシック Code JP 12'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface enable-animations true

echo ""
echo "================================"
echo "  Theme setup completed!"
echo ""
echo "  GTK テーマ  : $GTK_THEME_NAME"
echo "  アイコン    : $ICON_THEME_NAME"
echo "  カーソル    : $CURSOR_THEME_NAME"
echo "  Font        : Meiryo UI 11"
echo "  Mono font   : 源ノ角ゴシック Code JP 12"
echo ""
echo "  Note: Meiryo UI requires manual font installation."
echo "  Copy meiryo.ttc, meiryob.ttc to ~/.local/share/fonts/"
echo "  then run: fc-cache -fv"
echo "================================"
echo ""
