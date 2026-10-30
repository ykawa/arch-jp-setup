#!/bin/bash
# システム共通設定（全デスクトップ環境共通）
set -e

echo "================================"
echo "  Common System Configuration"
echo "================================"
echo ""

# Step 1: Disable Manjaro Hello
sudo pacman -Rns --noconfirm manjaro-hello 2>/dev/null || true

# Step 2: Disable CachyOS Hello
sudo pacman -Rns --noconfirm cachyos-hello 2>/dev/null || true
echo ""

# Step 3: Configure systemd timeout
echo "Configuring systemd timeout..."
if ! grep -q "DefaultTimeoutStopSec=10s" /etc/systemd/system.conf; then
    sudo sed -i 's/^#DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=10s/' /etc/systemd/system.conf
fi
echo ""

# Step 4: Rename Japanese directories to English
echo "Renaming Japanese directories to English..."

mkdir -p "$HOME/.config"
cat > "$HOME/.config/user-dirs.conf" << 'EOF'
enabled=False
EOF

cat > "$HOME/.config/user-dirs.dirs" << 'EOF'
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
XDG_PROJECTS_DIR="$HOME/Projects"
EOF

[ -d "$HOME/画像" ] && mv "$HOME/画像" "$HOME/Pictures" 2>/dev/null || true
[ -d "$HOME/テンプレート" ] && mv "$HOME/テンプレート" "$HOME/Templates" 2>/dev/null || true
[ -d "$HOME/ダウンロード" ] && mv "$HOME/ダウンロード" "$HOME/Downloads" 2>/dev/null || true
[ -d "$HOME/ドキュメント" ] && mv "$HOME/ドキュメント" "$HOME/Documents" 2>/dev/null || true
[ -d "$HOME/デスクトップ" ] && mv "$HOME/デスクトップ" "$HOME/Desktop" 2>/dev/null || true
[ -d "$HOME/ビデオ" ] && mv "$HOME/ビデオ" "$HOME/Videos" 2>/dev/null || true
[ -d "$HOME/公開" ] && mv "$HOME/公開" "$HOME/Public" 2>/dev/null || true
[ -d "$HOME/音楽" ] && mv "$HOME/音楽" "$HOME/Music" 2>/dev/null || true
# xdg-user-dirs 0.20 以降で追加された PROJECTS
[ -d "$HOME/プロジェクト" ] && mv "$HOME/プロジェクト" "$HOME/Projects" 2>/dev/null || true

cat > "$HOME/.config/user-dirs.locale" << 'EOF'
ja_JP
EOF

LANG=C xdg-user-dirs-update --force
echo ""

# Step 5: Configure autologin for tty3-5
echo "Configuring autologin for tty3-5..."
sudo mkdir -p /etc/systemd/system/getty@tty{3,4,5}.service.d

cat << EOF | sudo tee /etc/systemd/system/getty@tty3.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF

cat << EOF | sudo tee /etc/systemd/system/getty@tty4.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF

cat << EOF | sudo tee /etc/systemd/system/getty@tty5.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF
echo ""

echo "================================"
echo "  Common system configuration completed!"
echo "================================"
echo ""
