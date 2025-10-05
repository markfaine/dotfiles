#!/usr/bin/env bash

set -euo pipefail

# Prepare Mise config by removing existing config to avoid conflicts with dotfile-managed configuration
echo "Checking for existing Mise config..."
if [[ -f "$HOME/.config/mise/config.toml" ]]; then
    echo "Backing up existing Mise config..."
    mv "$HOME/.config/mise/config.toml" "$HOME/.config/mise/config.toml.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Existing Mise config backed up and removed."
else
    echo "No existing Mise config found."
fi
