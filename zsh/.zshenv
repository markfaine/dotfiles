export GIT_SSL_NO_VERIFY=true
skip_global_compinit=1

# Add neovim to the path
PATH="$PATH:/opt/nvim-linux64/bin"
export PATH

# Set editor
export DISABLE_AUTO_TITLE=true
export EDITOR='nvim'

# Aliases
alias vi=/opt/nvim-linux64/bin/nvim
alias vim=/opt/nvim-linux64/bin/nvim
alias mux=tmuxinator

# Add username to prompt
export PS1="%n $PS1"

# direnv support
eval "$(direnv export zsh)"

# Source fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Source ASDF
. "$HOME/.asdf/asdf.sh"