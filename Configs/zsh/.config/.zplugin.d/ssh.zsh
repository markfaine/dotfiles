# This is configuration for the zimfw/ssh plugin
# see: https://github.com/zimfw/ssh

# SSH zim module configuration {{{
# I currenlty only use public key files in WSL 
# so this is disabled for non WSL
# sessions where I would use yubikey keys
if [[ "${WSL_DISTRO_NAME:-}" != "" ]]; then
    zstyle ':zim:ssh' ids 'id_rsa' 'id_bean-rsa' 
fi
# End SSH zim module configuration }}}

