#!/bin/bash
# This script installs and enables Avahi daemon for network service discovery
set -e

echo "================================"
echo "  Avahi Setup Script"
echo "================================"
echo ""

paru -S --needed --noconfirm avahi nss-mdns

sudo systemctl enable avahi-daemon.service

# Wait a moment for services to stabilize
sleep 2

# Verify service status
echo "Final service status:"
if systemctl is-enabled avahi-daemon.service >/dev/null 2>&1 \
    && systemctl is-active avahi-daemon.service >/dev/null 2>&1; then
    echo "avahi-daemon.service: enabled and active"
else
    echo "✗ avahi-daemon.service: configuration issue"
    exit 1
fi

# Check if Avahi is responding
if command -v avahi-browse &>/dev/null; then
    echo "Avahi tools available"
    echo "- You can use 'avahi-browse -a' to discover services"
fi

echo ""
echo "Avahi setup completed successfully!"
echo ""
echo "================================"
