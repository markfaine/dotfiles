# direnv support
export DIRENV_LOG_FORMAT=

# Source ASDF
#
# Prepend ~/.local/bin to path
path=($HOME/.local/bin $path)

# asdf
export ASDF_DATA_DIR="$HOME/.asdf"
path=("$ASDF_DATA_DIR/shims" $path)

# Rust exclude
export RUST_WITHOUT=rust-docs

# Configure editor
alias svim="/usr/bin/vi" # stock vim
if command -v nvim &>/dev/null; then
    export EDITOR=nvim
    alias vim="$EDITOR"
    alias vi="$EDITOR"
fi

# Tmux alias
if command -v tmuxinator &>/dev/null; then
    alias mux="tmuxinator"
fi

# alias rm
alias rm='echo "This is not the command you are looking for."; false'
alias trm='trash-put'

# Mason bin directory
path=("$HOME/.local/share/nvim/mason/bin" $path )

# Setup trash
if [[ ! -d "$HOME/.Trash" ]]; then
    mkdir -p "$HOME/.Trash"
fi

# Add yarn global bin to path
if command -v yarn &>/dev/null; then
    path=("$(yarn global bin)" $path)
fi

# Prepend dot to path
path=('.' $path)
export PATH
