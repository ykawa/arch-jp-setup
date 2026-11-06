#!/bin/bash
# Web ブラウザ
# @group: ブラウザ
# @item: google-chrome Google Chrome
# @item: firefox Firefox @off
# @item: chromium Chromium @off
# @provides: google-chrome browser google-chrome-stable google-chrome.desktop
# @provides: firefox browser firefox firefox.desktop
# @provides: chromium browser chromium chromium.desktop
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/lib/package-groups.sh"

echo "================================"
echo "  ブラウザ"
echo "================================"
echo ""

echo "選択したブラウザをインストールしています..."
install_selected_items "$0"

# Firefox を入れたらログイン時に起動する（PC ごとに変えた起動方法は上書きしない）
AUTOSTART_FILE="$HOME/.config/autostart/firefox.desktop"
if ! pacman -Q firefox &>/dev/null; then
    echo "firefox is not installed, skipping autostart"
elif [ -e "$AUTOSTART_FILE" ]; then
    echo "$AUTOSTART_FILE already exists, skipping"
else
    mkdir -p "$(dirname "$AUTOSTART_FILE")"
    cat >"$AUTOSTART_FILE" <<'EOF'
[Desktop Entry]
Type=Application
Name=Firefox
Comment=ログイン時に Firefox を起動する
Exec=firefox
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
EOF
    echo "Created $AUTOSTART_FILE"
fi

echo ""
echo "ブラウザのインストールが完了しました"
echo "================================"
echo ""
