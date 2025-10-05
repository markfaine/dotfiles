#!/usr/bin/env bash

set -euo pipefail

# Install kitty {{{
echo "Checking if Kitty is already installed..."
if [[ -d ~/.local/kitty.app ]]; then
    echo "Kitty is already installed. Skipping installation."
else
    echo "Installing Kitty..."
    if ! curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin; then
        echo "Error: Failed to install Kitty." >&2
        exit 1
    fi
    echo "Kitty installed successfully."
fi
# End install kitty }}}

# Desktop Integration {{{

# Create symbolic links to add kitty and kitten to PATH (assuming ~/.local/bin is in your system-wide PATH) {{{
if [[ ! -e ~/.local/kitty.app/bin/kitty && ! -e ~/.local/kitty.app/bin/kitten ]]; then
    echo "Kitty binaries not found. Skipping desktop integration."
    exit 0
fi

echo "Setting up symbolic links for Kitty..."
mkdir -p ~/.local/bin
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
echo "Symbolic links created."
# End Create symbolic links to add kitty and kitten to PATH (assuming ~/.local/bin is in your system-wide PATH) }}}

# Place the kitty.desktop file somewhere it can be found by the OS {{{
echo "Copying desktop files..."
mkdir -p ~/.local/share/applications
cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
# End Place the kitty.desktop file somewhere it can be found by the OS }}}

# If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file {{{
cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
# End If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file }}}

# Update the paths to the kitty and its icon in the kitty desktop file(s) {{{
echo "Updating desktop file paths..."
sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
echo "Desktop files updated."
# Update the paths to the kitty and its icon in the kitty desktop file(s) }}}

# Make xdg-terminal-exec (and hence desktop environments that support it use kitty) {{{
echo "Setting up xdg-terminal-exec..."
mkdir -p ~/.config
echo 'kitty.desktop' >~/.config/xdg-terminals.list
echo "xdg-terminal-exec configured."
# End Make xdg-terminal-exec (and hence desktop environments that support it use kitty) }}}

# End Desktop Integration }}}

echo "Kitty setup complete."
