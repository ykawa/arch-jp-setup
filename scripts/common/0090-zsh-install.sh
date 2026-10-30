#!/bin/bash
# This script installs zsh and sets it as the default shell
# @group: zsh (デフォルトシェル化 / starship)
set -e

echo "================================"
echo "  Zsh Installation Script"
echo "================================"
echo ""

# Get current user
CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"
echo ""

paru -S --needed --noconfirm \
    zsh \
    zsh-completions \
    zsh-syntax-highlighting \
    zsh-autosuggestions \
    zsh-history-substring-search \
    starship \
    || true

echo "Zsh installed successfully:"
zsh --version

echo ""
echo "Setting zsh as default shell for user: $CURRENT_USER"

# Get the full path to zsh
ZSH_PATH=$(which zsh)
echo "Zsh path: $ZSH_PATH"

# Check if zsh is in /etc/shells
if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "Adding zsh to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi

# Change default shell
echo "Changing default shell to zsh..."
sudo chsh -s "$ZSH_PATH" "$CURRENT_USER"

echo ""
echo "Setting up .zshrc via dotfiles management..."

echo ""
echo "Zsh installation and setup completed successfully!"
echo ""
echo "================================"
