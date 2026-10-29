#!/bin/bash
# This script enables and starts the SSH daemon for remote access
set -e

echo "================================"
echo "  SSH Daemon Setup Script"
echo "================================"
echo ""

# Check if SSH daemon is already running
if systemctl is-active --quiet sshd; then
    echo "SSH daemon is already running:"
    echo "  Status: $(systemctl is-active sshd)"
    echo "  Enabled: $(systemctl is-enabled sshd)"
    echo "================================"
    exit 0
fi

echo "Setting up SSH daemon..."
echo ""

# Enable SSH service to start on boot
sudo systemctl enable --now sshd
echo "SSH daemon enabled for startup"

echo ""
echo "SSH daemon setup completed successfully!"
echo ""
echo "================================"
