#!/usr/bin/env bash

set -euo pipefail

echo "Checking for Neovim..."
if ! command -v nvim >/dev/null 2>&1; then
    echo "Error: Neovim not found. Please install Neovim first." >&2
    exit 1
fi

echo "Syncing Neovim plugins with Lazy..."
if nvim --headless -u ~/.config/nvim/init.lua -c 'lua require("lazy").sync()' -c 'qa!'; then
    echo "Neovim plugins synced successfully."
else
    echo "Error: Failed to sync Neovim plugins." >&2
    exit 1
fi
