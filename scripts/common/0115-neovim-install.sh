#!/bin/bash
# This script installs Neovim and the tools LazyVim (Omarchy-style config) relies on
# @group: Neovim (LazyVim)
set -e

echo "================================"
echo "  Neovim Installation Script"
echo "================================"
echo ""

# neovim: editor itself
# tree-sitter-cli: builds nvim-treesitter parsers
# luarocks: lazy.nvim rockspec support
# lazygit: <Space>gg in LazyVim
# fzf/ripgrep/fd: pickers and search
echo "Installing Neovim and LazyVim dependencies..."
paru -S --needed --noconfirm \
    neovim \
    tree-sitter-cli \
    luarocks \
    lazygit \
    fzf \
    ripgrep \
    fd \
    || true

echo ""
echo "Neovim installation completed successfully!"
echo ""
echo "================================"
