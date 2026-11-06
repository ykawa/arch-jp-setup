#!/bin/bash
# This script configures Caps Lock to function as Ctrl for both virtual console and X11/Wayland
set -e

echo "================================"
echo "  Caps Lock to Ctrl Setup"
echo "================================"
echo ""

# Remap CapsLock to Left Control at the hardware level via hwdb (udev)
set -euo pipefail

HWDB_DIR="/etc/udev/hwdb.d"
HWDB_FILE="${HWDB_DIR}/90-caps2ctrl.hwdb"

sudo mkdir -p "$HWDB_DIR"

sudo tee "$HWDB_FILE" >/dev/null <<'EOF'
# Built-in (PS/2) keyboard
evdev:atkbd:*
 KEYBOARD_KEY_3a=leftctrl    # 0x3a = CapsLock

# USB Keyboards in General
evdev:input:b0003v*p*
 KEYBOARD_KEY_70039=leftctrl  # 0x39(HID) = CapsLock

# Bluetooth keyboard (if needed)
evdev:input:b0005v*p*
 KEYBOARD_KEY_70039=leftctrl
EOF

# Update hwdb and trigger (use systemd-hwdb when available)
if command -v systemd-hwdb >/dev/null 2>&1; then
    sudo systemd-hwdb update
else
    sudo udevadm hwdb --update
fi
sudo udevadm trigger --sysname-match="event*" --subsystem-match=input

# Show active mapping proof-of-life
if command -v libinput >/dev/null 2>&1; then
    echo "libinput devices (for sanity check):"
    if libinput list-devices >/dev/null 2>&1; then
        sudo libinput list-devices | sed -n '1,200p'
    else
        echo "(skipped: permission denied; harmless for this setup)"
    fi
fi

echo ""
echo "Caps Lock to Ctrl setup completed successfully!"
echo ""
echo "================================"
