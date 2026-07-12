#!/bin/bash
# Wait for the smart card daemon (pcscd) to fully initialize your YubiKey
sleep 3

# Launch KeePassXC
rsync -av ~/personal.kdbx /volume1/containers/webdav/data/ &>/dev/null
keepassxc ~/personal.kdbx &
