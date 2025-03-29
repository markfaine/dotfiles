# Source ASDF
#
# Prepend ~/.local/bin to path
path=($HOME/.local/bin $path)

# asdf
export ASDF_DATA_DIR="$HOME/.asdf"
path=("$ASDF_DATA_DIR/shims" $path)
export "PATH"

# Rust exclude
export RUST_WITHOUT=rust-docs

# Configure editor
if command -v nvim &>/dev/null; then
    export EDITOR=nvim
    alias vim="$EDITOR"
    alias vi="$EDITOR"
fi

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

# Set pvenv venvs location
export PVENV_HOME="$HOME/.venvs"

# Prepend dot to path
path=('.' $path)
export PATH

# direnv support
# DIRENV_DIFF
if [[ -z "$DIRENV_DIFF" ]]; then
    export DIRENV_WARN_TIMEOUT=1m
    export DIRENV_LOG_FORMAT=
    eval "$(direnv hook zsh)"
fi

# Source aliases
. "$HOME/.aliases"
