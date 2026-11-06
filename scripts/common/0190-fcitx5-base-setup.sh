#!/bin/bash
# Fcitx5 基本セットアップ（全デスクトップ環境共通）
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "================================"
echo "  Fcitx5 Base Setup"
echo "================================"
echo ""

# Step 1: パッケージインストール
echo "Step 1: Installing fcitx5-im and fcitx5-mozc..."
paru -S --needed --noconfirm fcitx5-im
# fcitx5-mozc-ut（0185）が入っていれば provides で満たされるので、公式の fcitx5-mozc は入れない
if pacman -T fcitx5-mozc &>/dev/null; then
    echo "fcitx5-mozc (or a provider such as fcitx5-mozc-ut) is already installed"
else
    paru -S --needed --noconfirm fcitx5-mozc
fi
echo ""

# Step 2: 環境変数設定（~/.config/environment.d/ へ移行）
# /etc/environment は非推奨。systemd user session で読まれる environment.d を使用する。
# GTK_IM_MODULE はグローバル設定しない：
#   GTK4 は Wayland text-input-v3 プロトコルをネイティブ使用するため不要。
#   Chrome/Slack/Electron は --enable-wayland-ime フラグで対応（Step 7）。
echo "Step 2: Configuring environment variables..."

# 古い /etc/environment の設定を削除（移行クリーンアップ）
ENV_FILE="/etc/environment"
sudo sed -i '/^GTK_IM_MODULE=/d' "$ENV_FILE"
sudo sed -i '/^QT_IM_MODULE=/d' "$ENV_FILE"
sudo sed -i '/^XMODIFIERS=/d' "$ENV_FILE"
echo "Removed legacy IM settings from $ENV_FILE"

# systemd environment.d に設定
ENVD_DIR="$HOME/.config/environment.d"
mkdir -p "$ENVD_DIR"
cat >"$ENVD_DIR/fcitx5.conf" <<'EOF'
# fcitx5 input method environment variables
# XMODIFIERS: XWayland・レガシーX11アプリ向け
XMODIFIERS=@im=fcitx
# QT_IM_MODULE: Qt 内蔵の Wayland 入力コンテキスト（text-input-v3）経由で fcitx5 を使う。
#   fcitx5 の Qt プラグインをロードしないため、Qt アプリでのプラグイン起因のクラッシュを避けられる。
QT_IM_MODULE=wayland
EOF
echo "Created $ENVD_DIR/fcitx5.conf"
echo ""

# Step 3: Fcitx5設定ファイル
echo "Step 3: Creating fcitx5 configuration files..."
CONFIG_DIR="$HOME/.config/fcitx5"
mkdir -p "$CONFIG_DIR/conf"

# profile設定
cat >"$CONFIG_DIR/profile" <<'EOF'
[Groups/0]
Name=デフォルト
Default Layout=jp
DefaultIM=mozc

[Groups/0/Items/0]
Name=mozc
Layout=

[GroupOrder]
0=デフォルト
EOF

# config設定
cat >"$CONFIG_DIR/config" <<'EOF'
[Hotkey]
TriggerKeys=
EnumerateWithTriggerKeys=False
AltTriggerKeys=
EnumerateForwardKeys=
EnumerateBackwardKeys=
EnumerateSkipFirst=False
EnumerateGroupForwardKeys=
EnumerateGroupBackwardKeys=
ActivateKeys=
DeactivateKeys=
PrevPage=
NextPage=
PrevCandidate=
NextCandidate=
TogglePreedit=

[Behavior]
ActiveByDefault=True
resetStateWhenFocusIn=Program
ShareInputState=Program
PreeditEnabledByDefault=True
ShowInputMethodInformation=True
showInputMethodInformationWhenFocusIn=True
CompactInputMethodInformation=True
ShowFirstInputMethodInformation=True
DefaultPageSize=10
OverrideXkbOption=False
CustomXkbOption=
EnabledAddons=
DisabledAddons=
PreloadInputMethod=True
AllowInputMethodForPassword=False
ShowPreeditForPassword=False
AutoSavePeriod=30
EOF

# mozc.conf設定
cat >"$CONFIG_DIR/conf/mozc.conf" <<'EOF'
InitialMode=Direct
InputState=All
Vertical=True
ExpandMode="On Focus"
PreeditCursorPositionAtBeginning=False
ExpandKey=
EOF

# xim.conf設定
cat >"$CONFIG_DIR/conf/xim.conf" <<'EOF'
UseOnTheSpot=True
EOF

chmod 644 "$CONFIG_DIR/profile" "$CONFIG_DIR/config" "$CONFIG_DIR/conf/mozc.conf" "$CONFIG_DIR/conf/xim.conf"
echo ""

# Step 4: Mozc設定データベース
echo "Step 4: Copying Mozc configuration database..."
MOZC_CONFIG_DIR="$HOME/.config/mozc"
mkdir -p "$MOZC_CONFIG_DIR"

SOURCE_MOZC_CONFIG="$REPO_ROOT/dot.config/mozc/config1.db"
if [ -f "$SOURCE_MOZC_CONFIG" ]; then
    # シンボリックリンクが存在する場合は削除してから実ファイルをコピー
    if [ -L "$MOZC_CONFIG_DIR/config1.db" ]; then
        rm "$MOZC_CONFIG_DIR/config1.db"
    fi
    cp "$SOURCE_MOZC_CONFIG" "$MOZC_CONFIG_DIR/config1.db"
    chmod 644 "$MOZC_CONFIG_DIR/config1.db"
    echo "Mozc configuration database copied"
else
    echo "Warning: Source Mozc config1.db not found at $SOURCE_MOZC_CONFIG"
fi
echo ""

# Step 5: autostart設定
echo "Step 5: Setting up autostart..."

# /etc/xdg/autostart に fcitx5 の autostart ファイルが存在する場合は不要
if [ -f "/etc/xdg/autostart/org.fcitx.Fcitx5.desktop" ]; then
    echo "Fcitx5 autostart already provided by /etc/xdg/autostart/org.fcitx.Fcitx5.desktop, skipping"
else
    AUTOSTART_DIR="$HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"
    cat >"$AUTOSTART_DIR/org.fcitx.Fcitx5.desktop" <<'EOF'
[Desktop Entry]
Name[ca]=Fcitx 5
Name[da]=Fcitx 5
Name[de]=Fcitx 5
Name[fr]=Fcitx 5
Name[ja]=Fcitx 5
Name[ko]=Fcitx 5
Name[ru]=Fcitx 5
Name[vi]=Fcitx 5
Name[zh_CN]=Fcitx 5
Name[zh_TW]=Fcitx 5
Name=Fcitx 5
GenericName[ca]=Mètode d'entrada
GenericName[da]=Inputmetode
GenericName[de]=Eingabemethode
GenericName[fr]=Méthode de saisie
GenericName[ja]=入力メソッド
GenericName[ka]=შეტანის მეთოდი
GenericName[ko]=입력기
GenericName[ru]=Метод ввода
GenericName[vi]=Phương Thức Nhập
GenericName[zh_CN]=输入法
GenericName[zh_TW]=輸入法
GenericName=Input Method
Comment[ca]=Mètode d'entrada estàndard
Comment[da]=Start inputmetode
Comment[de]=Eingabemethode starten
Comment[fr]=Lancer la méthode de saisie
Comment[ja]=入力メソッドを開始
Comment[ko]=입력기 시작
Comment[ru]=Запустить метод ввода
Comment[vi]=Kiểu Gõ Bắt Đầu
Comment[zh_CN]=启动输入法
Comment[zh_TW]=啟動輸入法
Comment=Start Input Method
Exec=/usr/bin/fcitx5
Icon=fcitx
Terminal=false
Type=Application
Categories=System;Utility;
StartupNotify=false
X-GNOME-AutoRestart=false
X-GNOME-Autostart-Notify=false
X-KDE-autostart-after=panel
X-KDE-StartupNotify=false
X-KDE-Wayland-VirtualKeyboard=true
X-KDE-Wayland-Interfaces=org_kde_plasma_window_management
EOF
    echo "Created $AUTOSTART_DIR/org.fcitx.Fcitx5.desktop"
fi
echo ""

# Step 6: pacman IgnorePkg設定
echo "Step 6: Configuring pacman to ignore fcitx5/mozc updates..."
PACMAN_CONF="/etc/pacman.conf"

if grep -q "^IgnorePkg" "$PACMAN_CONF"; then
    if ! grep "^IgnorePkg" "$PACMAN_CONF" | grep -q "mozc-\*\|fcitx5-\*"; then
        sudo sed -i '/^IgnorePkg/s/$/ mozc-* fcitx5-*/' "$PACMAN_CONF"
    fi
elif grep -q "^#IgnorePkg" "$PACMAN_CONF"; then
    if grep "^#IgnorePkg" "$PACMAN_CONF" | grep -q "mozc-\*\|fcitx5-\*"; then
        sudo sed -i 's/^#IgnorePkg/IgnorePkg/' "$PACMAN_CONF"
    else
        sudo sed -i 's/^#IgnorePkg.*/IgnorePkg = mozc-* fcitx5-*/' "$PACMAN_CONF"
    fi
else
    sudo sed -i '/^\[options\]/a IgnorePkg = mozc-* fcitx5-*' "$PACMAN_CONF"
fi
echo ""

# Step 7: Chrome / Electron 系アプリの Wayland IME フラグ設定
# GTK_IM_MODULE の代わりに --enable-wayland-ime で Wayland IM プロトコルを直接使用する。
echo "Step 7: Configuring Wayland IME flags for Chrome/Electron apps..."

source "$REPO_ROOT/lib/link-config.sh"

# Google Chrome / Electron 汎用 / Typora はシンボリックリンクで管理
link_dotconfig "chrome-flags.conf" "$REPO_ROOT"
link_dotconfig "electron-flags.conf" "$REPO_ROOT"
link_dotconfig "typora" "$REPO_ROOT"

# Slack（~/.config/slack/ には他のアプリ生成ファイルも混在するため個別ファイル生成）
mkdir -p "$HOME/.config/slack"
cat >"$HOME/.config/slack/command-line-flags" <<'EOF'
--ozone-platform-hint=auto
--enable-wayland-ime
EOF

echo "Chrome/Electron Wayland IME flags configured"
echo ""

echo "================================"
echo "  Fcitx5 base setup completed!"
echo "================================"
echo ""
