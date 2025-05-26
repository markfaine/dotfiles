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
path=(. $path)
export PATH

# # Setup trash
if [[ ! -d "$HOME/.Trash" ]]; then
    mkdir -p "$HOME/.Trash"
fi

# # Source aliases
. "$HOME/.aliases"

# SSH Load
. "$HOME/.load_ssh"
