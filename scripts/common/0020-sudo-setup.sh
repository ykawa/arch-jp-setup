#!/bin/bash
set -e

CURRENT_USER=$(whoami)

# Check if the script is running as root
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: This script should not be run as root."
    echo "Please run as a regular user with sudo privileges."
    exit 1
fi

# Create sudoers file for the current user
SUDOERS_FILE="/etc/sudoers.d/99-$CURRENT_USER-nopasswd"

# Create the sudoers entry with explicit specification
echo "$CURRENT_USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_FILE" >/dev/null

sudo chmod 440 "$SUDOERS_FILE"

echo ""
echo "Sudo setup completed successfully!"
echo ""
echo "================================"
