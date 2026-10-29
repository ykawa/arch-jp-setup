#!/bin/bash
# plymouth / cachyos-plymouth-bootanimation / cachyos-plymouth-theme をクリーンに除去
set -e

echo "================================"
echo "  Plymouth Removal"
echo "================================"
echo ""

PACKAGES_TO_REMOVE=(cachyos-plymouth-bootanimation cachyos-plymouth-theme plymouth)

installed=()
for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        installed+=("$pkg")
    fi
done

if [ ${#installed[@]} -eq 0 ]; then
    echo "plymouth is not installed, skipping"
    exit 0
fi

echo "Removing packages: ${installed[*]}"
sudo pacman -Rns --noconfirm "${installed[@]}"
echo ""

MKINITCPIO_CONF="/etc/mkinitcpio.conf"
if [ -f "$MKINITCPIO_CONF" ] && grep -q '\bplymouth\b' "$MKINITCPIO_CONF"; then
    echo "Removing plymouth hook from mkinitcpio.conf..."
    sudo cp "$MKINITCPIO_CONF" "$MKINITCPIO_CONF.backup"
    sudo sed -i -E 's/\bplymouth //g; s/ plymouth\b//g; s/\bplymouth\b//g' "$MKINITCPIO_CONF"

    echo "Regenerating initramfs..."
    sudo mkinitcpio -P
    echo ""
fi

GRUB_DEFAULT_FILE="/etc/default/grub"
if [ -f "$GRUB_DEFAULT_FILE" ] && command -v grub-mkconfig &>/dev/null; then
    if grep -qE '^GRUB_CMDLINE_LINUX_DEFAULT=.*\bsplash\b' "$GRUB_DEFAULT_FILE"; then
        echo "Removing splash param from GRUB_CMDLINE_LINUX_DEFAULT..."
        sudo cp "$GRUB_DEFAULT_FILE" "$GRUB_DEFAULT_FILE.backup"
        current_params=$(sed -nE 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)"$/\1/p' "$GRUB_DEFAULT_FILE")
        new_params=$(echo "$current_params" | sed -E 's/\bsplash\b//g' | xargs)
        sudo sed -i -E "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$new_params\"|" "$GRUB_DEFAULT_FILE"
    fi

    echo "Regenerating GRUB configuration..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    echo ""
fi

echo "Plymouth removal completed!"
echo ""
