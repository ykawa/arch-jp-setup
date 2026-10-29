#!/bin/bash
# This script installs Docker and related container tools
# @group: Docker
set -e

echo "=================================="
echo "  Container Tools Installation"
echo "=================================="
echo ""

echo "Installing Docker and container tools..."
paru -S --needed --noconfirm \
    docker \
    docker-compose \
    docker-buildx \
    || true

# Configure Docker for user access
echo ""
echo "Configuring Docker for user access..."
sudo usermod -aG docker $USER
sudo systemctl enable docker

echo ""
echo "Container tools installation completed successfully!"
echo "Docker access requires re-login to take effect."
echo ""
echo "Please reboot your system to apply the changes."
echo ""
echo "=================================="
