export GIT_SSL_NO_VERIFY=true
skip_global_compinit=1

# Add neovim to the path
PATH="$PATH:/opt/nvim-linux64/bin"
export PATH
alias vi=/opt/nvim-linux64/bin/nvim
alias vim=/opt/nvim-linux64/bin/nvim

# Source ASDF
. "$HOME/.asdf/asdf.sh"
