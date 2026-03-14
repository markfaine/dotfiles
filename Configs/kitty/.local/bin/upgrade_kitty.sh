#!/usr/bin/env bash
# ==============================================================================
# Upgrade Kitty
# ==============================================================================
info "Checking if Kitty is installed..."
if [[ -d "$KITTY_APP_DIR" ]]; then
    info "Kitty is already installed. Upgrading..."
else
    info "Upgrading Kitty..."
    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: curl is required to install Kitty." >&2
        exit 1
    fi
	if ! run_cmd "Download and run Kitty installer" bash -c 'curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin'; then
        echo "Error: Failed to install Kitty." >&2
        exit 1
    fi
    info "Kitty upgraded successfully."
fi
