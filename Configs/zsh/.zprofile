# # Completion for tmuxinator

# # Configure editor
alias oldvim='NVIM_APPNAME=oldvim nvim'
export EDITOR=nvim
alias vim="EDITOR"
alias vi="EDITOR"

# # Mason bin directory
path=($path "$HOME/.local/share/nvim/mason/bin")

# # Prepend ~/.local/bin to path
path=($path $HOME/.local/bin)

# # Export path changes
export PATH

# # Setup trash
if [[ ! -d "$HOME/.Trash" ]]; then
    mkdir -p "$HOME/.Trash"
fi

# # Source aliases
. "$HOME/.aliases"

# # Attach yubikey, if wsl
# if [[ -f "/etc/wsl.conf" ]]; then
#     if ! usbipd.exe list | grep -qi attached; then
#         usbipd.exe attach --busid 5-1 --wsl || true
#     fi
# fi

function ssh_load(){
    eval "$(ssh-agent -s; SSH_ASKPASS=$SSH_ASKPASS)"
    usbipd.exe attach --busid 5-1 --wsl || true
    ssh-add -K || true
    #ssh-add ~/.ssh/id_rsa
    #ssh-add ~/.ssh/id_bean-rsa
}
ssh_load
