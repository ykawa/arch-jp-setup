#!/bin/bash
# This script removes unwanted packages and configurations to clean up the system
set -e

echo "========================================"
echo "  Remove Unwanted Packages"
echo "  System Cleanup"
echo "========================================"
echo ""

echo "Starting cleanup of unwanted packages and configurations..."
echo ""

# Remove unwanted packages first
echo "Removing unwanted packages..."

paru -Rns --noconfirm \
    clipit \
    pidgin \
    pidgin-libnotify \
    vivaldi \
    vivaldi-bin \
    vivaldi-stable \
    nano \
    nano-syntax-highlighting \
    micro \
    celluloid \
    lollypop \
    2>/dev/null || true

echo ""
echo "Removing application configurations and cache..."

# Clean package cache
echo ""
echo "Cleaning package cache..."
yay -Sc --noconfirm || echo "Warning: Failed to clean package cache"

# Remove orphaned packages
echo ""
echo "Removing orphaned packages..."
orphaned_packages=$(pacman -Qtdq 2>/dev/null || true)
if [ -n "$orphaned_packages" ]; then
    echo "Found orphaned packages:"
    echo "$orphaned_packages"
    echo ""
    sudo pacman -Rns --noconfirm $orphaned_packages || echo "Warning: Failed to remove some orphaned packages"
    echo "Orphaned packages removed"
else
    echo "No orphaned packages found"
fi

echo ""
echo "Additional cleanup..."

# Remove .desktop files for removed applications
desktop_files_to_remove=(
    "$HOME/.local/share/applications/vivaldi.desktop"
    "$HOME/.local/share/applications/pidgin.desktop"
    "$HOME/.local/share/applications/lollypop.desktop"
    "$HOME/.local/share/applications/celluloid.desktop"
)

for desktop_file in "${desktop_files_to_remove[@]}"; do
    if [ -f "$desktop_file" ]; then
        rm -f "$desktop_file"
        echo "Removed desktop file: $(basename "$desktop_file")"
    fi
done

# Update desktop database
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    echo "Desktop database updated"
fi

echo ""
echo "========================================"
echo "  Unwanted Packages Removal Completed"
echo "========================================"
echo ""
