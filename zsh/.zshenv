export GIT_SSL_NO_VERIFY=true
skip_global_compinit=1

# Add neovim to the path
path=('.' $path)

# Set editor
export DISABLE_AUTO_TITLE=true

# Aliases
if [[ -x "$HOME/apps/nvim/bin/nvim" ]]; then
    alias nvim="$HOME/apps/nvim/bin/nvim"
    alias vim='nvim'
    alias vi='nvim'
    path+="$HOME/apps/nvim/bin"
    export EDITOR='nvim'
fi

# Export path changes
export PATH

# Tmux alias
alias mux=tmuxinator

# direnv support
eval "$(direnv export zsh)"

# Source fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Source ASDF
export ASDF_FORCE_PREPEND=no
. "$HOME/.asdf/asdf.sh"
