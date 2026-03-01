#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Kitty Pre Hook
# ==============================================================================

KITTY_APP_DIR="$HOME/.local/kitty.app"
KITTY_BIN_DIR="$KITTY_APP_DIR/bin"
KITTY_SHARE_APPS_DIR="$KITTY_APP_DIR/share/applications"
KITTY_ICON_PATH="$KITTY_APP_DIR/share/icons/hicolor/256x256/apps/kitty.png"
LOCAL_BIN_DIR="$HOME/.local/bin"
LOCAL_APPS_DIR="$HOME/.local/share/applications"

# ==============================================================================
# Install Kitty
# ==============================================================================
echo "Checking if Kitty is already installed..."
if [[ -d "$KITTY_APP_DIR" ]]; then
    echo "Kitty is already installed. Skipping installation."
else
    echo "Installing Kitty..."
    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: curl is required to install Kitty." >&2
        exit 1
    fi
    if ! curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin; then
        echo "Error: Failed to install Kitty." >&2
        exit 1
    fi
    echo "Kitty installed successfully."
fi

# ==============================================================================
# Desktop Integration
# ==============================================================================

# Create symbolic links for kitty and kitten
if [[ ! -x "$KITTY_BIN_DIR/kitty" || ! -x "$KITTY_BIN_DIR/kitten" ]]; then
    echo "Kitty binaries not found. Skipping desktop integration."
    exit 0
fi

echo "Setting up symbolic links for Kitty..."
mkdir -p "$LOCAL_BIN_DIR"
ln -sf "$KITTY_BIN_DIR/kitty" "$LOCAL_BIN_DIR/kitty"
ln -sf "$KITTY_BIN_DIR/kitten" "$LOCAL_BIN_DIR/kitten"
echo "Symbolic links created."

echo "Copying desktop files..."
mkdir -p "$LOCAL_APPS_DIR"
cp "$KITTY_SHARE_APPS_DIR/kitty.desktop" "$LOCAL_APPS_DIR/"

if [[ -f "$KITTY_SHARE_APPS_DIR/kitty-open.desktop" ]]; then
    cp "$KITTY_SHARE_APPS_DIR/kitty-open.desktop" "$LOCAL_APPS_DIR/"
fi

echo "Updating desktop file paths..."
sed -i "s|Icon=kitty|Icon=$KITTY_ICON_PATH|g" "$LOCAL_APPS_DIR"/kitty*.desktop
sed -i "s|Exec=kitty|Exec=$KITTY_BIN_DIR/kitty|g" "$LOCAL_APPS_DIR"/kitty*.desktop
echo "Desktop files updated."

echo "Setting up xdg-terminal-exec..."
mkdir -p "$HOME/.config"
echo 'kitty.desktop' >"$HOME/.config/xdg-terminals.list"
echo "xdg-terminal-exec configured."

echo "Kitty setup complete."
