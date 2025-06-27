# # Completion for tmuxinator
# shellcheck shell=zsh

# # Configure editor
alias oldvim='NVIM_APPNAME=oldvim nvim'
export EDITOR=nvim
alias vim="$EDITOR"
alias vi="$EDITOR"

# # Mason bin directory
path=($path "$HOME/.local/share/nvim/mason/bin")

# # Prepend ~/.local/bin to path
path=($path $HOME/.local/bin)

# # Add npm modules to path
path=($path "$HOME/.config/node_modules/.bin")

# # Export path changes
path=(. $path)
export PATH

# # Setup trash
if [[ ! -d "$HOME/.Trash" ]]; then
  mkdir -p "$HOME/.Trash"
fi

# # Source aliases
if [[ -d "$HOME/.aliases" ]]; then
  . "$HOME/.aliases"
fi

# SSH Load
if [[ -d "$HOME/.load_ssh" ]]; then
  . "$HOME/.load_ssh"
fi

# Ansible
if [[ -f "$HOME/.work" ]]; then
  . "$HOME/.work"
fi
export ZPROFILE_LOADED=1
