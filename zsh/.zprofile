# Source ASDF
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
alias nvi='NVIM_APPNAME=newvim nvim'

# npm/yarn bin directory
path=($path "$HOME/development/python/nats-util/node_modules/.bin")

# Mason bin directory
path=($path "$HOME/.local/share/nvim/mason/bin")


# Setup trash
if [[ ! -d "$HOME/.Trash" ]]; then
    mkdir -p "$HOME/.Trash"
fi

# Add yarn global bin to path
if command -v yarn &>/dev/null; then
    path=($path "$(yarn global bin)")
fi

# Set pvenv venvs location
export PVENV_HOME="$HOME/.venvs"

# Prepend dot to path
path=('.' $path)
export PATH

# direnv support, looks for defined DIRENV_DIFF
if [[ -z "$DIRENV_DIFF" ]]; then
    export DIRENV_WARN_TIMEOUT=10s
    export DIRENV_LOG_FORMAT=
    eval "$(direnv hook zsh)"
fi

# Source aliases
. "$HOME/.aliases"

# Prepend ~/.local/bin to path
path=($path $HOME/.local/bin)

# Export path changes
export PATH

# Attach yubikey
if ! usbipd.exe list | grep -qi attached; then
    usbipd.exe attach --busid 5-1 --wsl
fi
function ssh_load(){
    export SSH_ASKPASS=/usr/bin/ssh-askpass
    eval "$(ssh-agent -s; SSH_ASKPASS=$SSH_ASKPASS)"
    ssh-add -K
}
ssh_load
