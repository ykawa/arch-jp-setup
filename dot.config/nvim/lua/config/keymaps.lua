-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Copy mouse selections to the system clipboard when the drag ends
vim.keymap.set("x", "<LeftRelease>", '<LeftRelease>"+ygv', { desc = "Copy mouse selection to clipboard" })
