export GIT_SSL_NO_VERIFY=true
skip_global_compinit=1

# Add neovim to the path
PATH="$PATH:/opt/nvim/bin"
export PATH

# Set editor
export DISABLE_AUTO_TITLE=true
export EDITOR='nvim'

# Aliases
alias vi=/opt/nvim/bin/nvim
alias nvim=/opt/nvim/bin/nvim
alias vim=/opt/nvim/bin/nvim
alias mux=tmuxinator

# direnv support
eval "$(direnv export zsh)"

# Source fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Source ASDF
. "$HOME/.asdf/asdf.sh"
