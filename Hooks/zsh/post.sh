#!/usr/bin/env bash

set -euo pipefail

# Setup Doppler for secrets management
echo "Checking for Doppler setup script..."
if [[ -x "$HOME/.local/bin/setup-doppler-env.sh" ]]; then
    echo "Running Doppler setup..."
    if "$HOME/.local/bin/setup-doppler-env.sh"; then
        echo "Doppler setup completed successfully."
    else
        echo "Error: Doppler setup failed." >&2
        exit 1
    fi
else
    echo "Doppler setup script not found. Skipping."
fi