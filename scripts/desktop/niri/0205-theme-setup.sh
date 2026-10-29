#!/bin/bash
# niri テーマ・アイコン・カーソル・フォント設定
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$REPO_ROOT/lib/link-config.sh"

echo "================================"
echo "  Theme Setup for niri"
echo "================================"
echo ""

# ── パッケージインストール ─────────────────────────────────

echo "[1/3] Installing theme packages..."
paru -S --needed --noconfirm \
    tokyonight-gtk-theme-git \
    papirus-icon-theme \
    bibata-cursor-theme \
    capitaine-cursors \
    gtk-theme-numix-sx \
    mint-l-icons \
    mint-l-theme \
    kvantum \
    || true

echo ""

# ── 設定ファイルのリンク ───────────────────────────────────

echo "[2/3] Linking config files..."
link_dotconfig "gtk-3.0"    "$REPO_ROOT"
link_dotconfig "gtk-4.0"    "$REPO_ROOT"
link_dotconfig "xsettingsd" "$REPO_ROOT"

echo ""

# ── gsettings（GNOME/GTK アプリ共通） ──────────────────────

echo "[3/3] Applying gsettings..."

gsettings set org.gnome.desktop.interface gtk-theme           'Numix-SX-FullDark'
gsettings set org.gnome.desktop.interface icon-theme          'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme        'Bibata-Modern-Ice'
gsettings set org.gnome.desktop.interface cursor-size         24
gsettings set org.gnome.desktop.interface font-name           'Meiryo UI 11'
gsettings set org.gnome.desktop.interface document-font-name  'Meiryo UI 11'
gsettings set org.gnome.desktop.interface monospace-font-name '源ノ角ゴシック Code JP 12'
gsettings set org.gnome.desktop.interface color-scheme        'prefer-dark'
gsettings set org.gnome.desktop.interface enable-animations   true

echo ""
echo "================================"
echo "  Theme setup completed!"
echo ""
echo "  GTK3  theme : Tokyonight-Dark  (gtk-3.0/settings.ini)"
echo "  GTK4  theme : Tokyonight-Dark  (gtk-4.0/settings.ini)"
echo "  Icon  theme : Papirus-Dark"
echo "  Cursor theme: Bibata-Modern-Classic (GTK3/4)"
echo "               Bibata-Modern-Ice     (GNOME/Cinnamon apps)"
echo "  Font        : Meiryo UI 11"
echo "  Mono font   : 源ノ角ゴシック Code JP 12"
echo ""
echo "  Note: Meiryo UI requires manual font installation."
echo "  Copy meiryo.ttc, meiryob.ttc to ~/.local/share/fonts/"
echo "  then run: fc-cache -fv"
echo "================================"
echo ""
