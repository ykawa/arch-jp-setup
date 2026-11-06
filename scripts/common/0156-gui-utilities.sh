#!/bin/bash
# 小物の GUI ユーティリティ
# @group: GUI ユーティリティ (LocalSend / Flameshot / galculator / wev)
set -e

echo "================================"
echo "  GUI Utilities Installation"
echo "================================"
echo ""

echo "Installing GUI utilities..."
paru -S --needed --noconfirm \
    localsend \
    flameshot \
    galculator \
    wev \
    || true

AUTOSTART_DIR="$HOME/.config/autostart"

# LocalSend はログイン時にトレイへ隠して起動する（アプリの自動起動設定と同じファイル名）
if pacman -Q localsend &>/dev/null; then
    mkdir -p "$AUTOSTART_DIR"
    cat >"$AUTOSTART_DIR/localsend_app.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=localsend_app
Comment=localsend_app startup script
Exec=/usr/lib/localsend/localsend --hidden
StartupNotify=false
Terminal=false
EOF
    echo "Created $AUTOSTART_DIR/localsend_app.desktop"
else
    echo "localsend is not installed, skipping autostart"
fi

# Flameshot はログイン時にトレイへ常駐させる（アプリの自動起動設定と同じファイル名）
if pacman -Q flameshot &>/dev/null; then
    mkdir -p "$AUTOSTART_DIR"
    cat >"$AUTOSTART_DIR/Flameshot.desktop" <<'EOF'
[Desktop Entry]
Name=flameshot
Icon=flameshot
Exec=flameshot
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF
    echo "Created $AUTOSTART_DIR/Flameshot.desktop"
else
    echo "flameshot is not installed, skipping autostart"
fi

echo ""
echo "GUI Utilities Installation completed!"
echo "================================"
echo ""
