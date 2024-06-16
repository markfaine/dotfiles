# Need by zim
skip_global_compinit=1

# Add dot to the path
path=('.' $path)

# Temporarily disabled due to an issue with MS terminal 
#export DISABLE_AUTO_TITLE=true

# Configure path, aliases, and environment variables for neovim
if [[ -x "$HOME/apps/nvim/bin/nvim" ]]; then
    alias nvim="$HOME/apps/nvim/bin/nvim"
    alias vim='nvim'
    alias vi='nvim'
    alias svim='/usr/bin/vim' # stock vim
    path+="$HOME/apps/nvim/bin"
    export EDITOR='nvim'
fi

# Export path changes
export PATH

# Tmux alias
TMUXINATOR="$(command -v tmuxinator)"
[ -x "$TMUXINATOR" ] && alias mux="$TMUXINATOR"

# direnv support
DIRENV="$(command -v direnv)"
[ -x "$DIRENV" ] && eval "$("$DIRENV" export zsh)"

# Source fzf
FZF="$(command -v fzf)"
[ -x "$FZF" ] && source <(fzf --zsh)

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Source ASDF
export ASDF_FORCE_PREPEND=no
. "$HOME/.asdf/asdf.sh"

# zoxide
eval "$(zoxide init zsh --cmd cd)"

# Git environment variables
export GIT_SSL_NO_VERIFY=true
