#!/bin/bash
# Japanese 106-key Keyboard Setup Script
# This script configures Japanese 106-key keyboard layout for both virtual console and X11/Wayland
set -e

echo "================================="
echo "  Japanese 106-key Keyboard Setup"
echo "================================="
echo ""

# Get current user
CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"
echo ""

echo "Step 1: Configuring virtual console (vconsole) for Japanese keyboard..."

# Configure vconsole for Japanese keyboard
VCONSOLE_FILE="/etc/vconsole.conf"

# Check and update vconsole.conf with Japanese keyboard layout
echo "Configuring Japanese keyboard layout in $VCONSOLE_FILE..."

# Check if configuration already matches what we want
if [ -f "$VCONSOLE_FILE" ] \
    && grep -q "^KEYMAP=jp106" "$VCONSOLE_FILE" \
    && grep -q "^FONT=lat9w-16" "$VCONSOLE_FILE"; then
    echo "Virtual console already configured for Japanese 106-key keyboard"
else
    # Create or update the configuration
    sudo tee "$VCONSOLE_FILE" >/dev/null <<'EOF'
# Virtual console configuration
KEYMAP=jp106
FONT=lat9w-16
EOF
    echo "Virtual console configured for Japanese 106-key keyboard"
fi

echo ""
echo "Step 2: Loading Japanese keyboard layout for current session..."

# Load the Japanese keymap for the current session
if command -v loadkeys &>/dev/null; then
    sudo loadkeys jp106
fi

echo ""
echo "Step 3: Configuring X11 for Japanese keyboard..."

# Create X11 keyboard configuration
X11_KEYBOARD_CONF="/etc/X11/xorg.conf.d/00-keyboard.conf"

echo "Creating X11 keyboard configuration: $X11_KEYBOARD_CONF"
sudo mkdir -p /etc/X11/xorg.conf.d/

sudo tee "$X11_KEYBOARD_CONF" >/dev/null <<'EOF'
# X11 Keyboard Configuration
# Japanese 106-key keyboard layout

Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "jp"
    Option "XkbModel" "jp106"
    Option "XkbVariant" ""
    Option "XkbOptions" "ctrl:nocaps"
EndSection
EOF

echo "X11 keyboard configuration created"

echo ""
echo "Step 4: Configuring locale for Japanese support..."

# Check if Japanese locale is available
if locale -a | grep -q "ja_JP.UTF-8"; then
    echo "Japanese locale (ja_JP.UTF-8) is available"
else
    echo "Installing Japanese locale support..."
    if ! grep -q "^ja_JP.UTF-8" /etc/locale.gen; then
        echo "ja_JP.UTF-8" | sudo tee /etc/locale.gen >/dev/null
        sudo locale-gen
        echo "Japanese locale generated"
    fi
fi

echo ""
echo "Step 5: Applying current session settings..."

echo ""
echo "Japanese 106-key keyboard setup completed successfully!"
echo ""
echo "================================"
