#!/bin/bash
# GRUBを利用している場合、起動時のスプラッシュ画面を無効化 (nosplash)
set -e

echo "================================"
echo "  GRUB nosplash Configuration"
echo "================================"
echo ""

GRUB_DEFAULT_FILE="/etc/default/grub"

if [ ! -f "$GRUB_DEFAULT_FILE" ] || ! command -v grub-mkconfig &>/dev/null; then
    echo "GRUB is not in use, skipping"
    exit 0
fi

echo "GRUB detected: $GRUB_DEFAULT_FILE"

if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*\bnosplash\b' "$GRUB_DEFAULT_FILE"; then
    echo "nosplash already configured, skipping"
    exit 0
fi

echo "Backing up $GRUB_DEFAULT_FILE..."
sudo cp "$GRUB_DEFAULT_FILE" "$GRUB_DEFAULT_FILE.backup"

echo "Updating GRUB_CMDLINE_LINUX_DEFAULT..."
current_params=$(sed -nE 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)"$/\1/p' "$GRUB_DEFAULT_FILE")
new_params=$(echo "$current_params" | sed -E 's/\bsplash\b//g' | xargs)
new_params="${new_params:+$new_params }nosplash"

sudo sed -i -E "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$new_params\"|" "$GRUB_DEFAULT_FILE"

echo "Regenerating GRUB configuration..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo ""
echo "GRUB nosplash configuration completed!"
echo ""
