# Configure editor
VIM="$(command -v vim)"
editor="$VIM"
if [[ -x "$HOME/apps/nvim/bin/nvim" ]]; then
    alias nvim="$HOME/apps/nvim/bin/nvim"
    alias vim='nvim'
    alias vi='nvim'
    alias svim="$VIM" # stock vim
    path=($HOME/apps/nvim/bin $path)
    editor='nvim'
fi
export EDITOR="$editor"

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Source ASDF
export ASDF_FORCE_PREPEND=no
ASDF_SCRIPT="$HOME/.asdf/asdf.sh"
[ -s "$ASDF_SCRIPT" ] && source "$ASDF_SCRIPT"

# Tmux alias
TMUXINATOR="$(command -v tmuxinator)"
[ -x "$TMUXINATOR" ] && alias mux="$TMUXINATOR"

# direnv support
DIRENV="$(command -v direnv)"
# Don't display direnv output
export DIRENV_LOG_FORMAT=
[ -x "$DIRENV" ] && eval "$("$DIRENV" hook zsh)"

# Source fzf
FZF="$(command -v fzf)"
[ -x "$FZF" ] && source <(fzf --zsh)

# Evaluate zoxide to integrate into shell
path=('.' $path)
path=($HOME/.local/bin $path)
export PATH

# Use zoxide
ZOXIDE="$HOME/.local/bin/zoxide"
[ -x "$ZOXIDE" ] && eval "$("$ZOXIDE" init zsh --cmd cd)"

# Initialize pass
PASS="$(command -v pass)"
[ -x "$PASS" ] && "$PASS" show docker-credential-helpers/docker-pass-initialized-check &>/dev/null

# Load ssh agent and resident keys
function ssh_load(){
    eval "$(ssh-agent -s; SSH_ASKPASS=/usr/bin/ssh-askpass)"
    ssh-add -K
}
export -f ssh_load
ssh_load
