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

# Source fzf
#if command -v fzf &>/dev/null; then
#    source <(fzf --zsh)
#fi

# Export path at the end
#export PATH

# Evaluate zoxide to integrate into shell
#ZOXIDE="$HOME/.local/bin/zoxide"
#[ -x "$ZOXIDE" ] && eval "$("$ZOXIDE" init zsh --cmd cd)"

# Initialize pass
#PASS="$(command -v pass)"
#[ -x "$PASS" ] && "$PASS" show docker-credential-helpers/docker-pass-initialized-check &>/dev/null

# Mason bin directory
path=("$HOME/.local/share/nvim/mason/bin" $path )

# Prepend dot to path
path=('.' $path)
export PATH
