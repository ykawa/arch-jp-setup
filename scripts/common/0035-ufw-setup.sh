#!/bin/bash
# This script configures UFW firewall if it's installed
set -e

echo "================================"
echo "  UFW Firewall Configuration"
echo "================================"
echo ""

# Check if UFW is installed
if ! command -v ufw &>/dev/null; then
    echo "UFW is not installed - skipping firewall configuration"
    echo ""
    exit 0
fi

echo "UFW is installed - configuring firewall..."
echo ""

# Allow SSH (22/tcp)
echo "Allowing SSH (22/tcp)..."
sudo ufw allow 22/tcp

echo ""
echo "UFW firewall configuration completed!"
echo ""
echo "Current UFW rules:"
sudo ufw status verbose || echo "UFW is not enabled yet"
echo ""
echo "To enable UFW:"
echo "  sudo ufw enable"
echo ""
