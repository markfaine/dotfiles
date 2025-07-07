#!/bin/bash

# Install kitty {{{
#curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
# End instlal kitty }}}

# Desktop Integration {{{

# Create symbolic links to add kitty and kitten to PATH (assuming ~/.local/bin is in your system-wide PATH) {{{
if [[ ! -e ~/.local/kitty.app/bin/kitty && ! -e ~/.local/kitty.app/bin/kitten ]]; then
    exit 0 # may not be installed here so do nothing if not
fi

mkdir -p ~/.local/bin
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
# End Create symbolic links to add kitty and kitten to PATH (assuming ~/.local/bin is in your system-wide PATH) }}}

# Place the kitty.desktop file somewhere it can be found by the OS {{{
cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
# End Place the kitty.desktop file somewhere it can be found by the OS }}}

# If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file {{{
cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
# End If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file }}}

# Update the paths to the kitty and its icon in the kitty desktop file(s) {{{
sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
# Update the paths to the kitty and its icon in the kitty desktop file(s) }}}

# Make xdg-terminal-exec (and hence desktop environments that support it use kitty) {{{
echo 'kitty.desktop' >~/.config/xdg-terminals.list
# End Make xdg-terminal-exec (and hence desktop environments that support it use kitty) }}}

# End Desktop Integration }}}
