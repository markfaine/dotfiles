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
. "$HOME/.aliases"

# SSH Load
. "$HOME/.load_ssh"

export CONTROLLER_INVENTORY=7
export CONTROLLER_HOST=n-msfc-aap.ndc.nasa.gov
export CONTROLLER_PASSWORD="V4&R0mfQn#rJw%cVYZ"
export CONTROLLER_USERNAME=bean
export CONTROLLER_VERIFY_SSL=false
export ZPROFILE_LOADED=1
