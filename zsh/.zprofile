# Configure editor
if [[ "${EDITOR:-}" == "" ]]; then
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
fi

# Load nvm
if [[ "${NVM_BIN:-}" == "" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
fi

# Initialize ASDF
function asdf_init(){
    export ASDF_FORCE_PREPEND=no
    ASDF_SCRIPT="$HOME/.asdf/asdf.sh"
    [ -s "$ASDF_SCRIPT" ] && source "$ASDF_SCRIPT"
}
if [[ "${ASDF_FORCE_PREPEND:-}" == "" ]]; then
    asdf_init
fi

# Tmux alias
TMUXINATOR="$(command -v tmuxinator)"
[ -x "$TMUXINATOR" ] && alias mux="$TMUXINATOR"

# Initialize direnv
function direnv_init(){
    DIRENV="$(command -v direnv)"
    # Don't display direnv output
    export DIRENV_LOG_FORMAT=
    if [[ -x "$DIRENV" ]]; then 
        eval "$("$DIRENV" hook zsh)"
        export DIRENV_INIT=true
    fi
}
if [[ "${DIRENV_INIT:-}" == "" ]]; then
    direnv_init
fi

# Initialize fzf
function fzf_init(){
    FZF="$(command -v fzf)"
    if [[ -x "$FZF" ]]; then
      source <(fzf --zsh)
      FZF_INIT=true
    fi
}
if [[ "${FZF_INIT:-}" == "" ]]; then
    fzf_init 
fi

# Initialize zoxide
function zoxide_init(){
    ZOXIDE="$HOME/.local/bin/zoxide"
    [ -x "$ZOXIDE" ] && eval "$("$ZOXIDE" init zsh --cmd cd)"
    ZOXIDE_INIT=true
}
if [[ "${ZOXIDE_INIT:-}" == "" ]]; then
  zoxide_init
fi

# Initialize pass
function pass_init(){
    PASS="$(command -v pass)"
    [ -x "$PASS" ] && "$PASS" show docker-credential-helpers/docker-pass-initialized-check &>/dev/null
    export PASS_INIT=true
}
if [[ "${PASS_INIT:-}" == "" ]]; then
  pass_init
fi

# Load ssh agent and resident keys
function ssh_load(){
    export SSH_ASKPASS=usr/bin/ssh-askpass
    eval "$(ssh-agent -s; SSH_ASKPASS=$SSH_ASKPASS)"
    ssh-add -K
}
if [[ "${SSH_ASKPASS:-}" == "" ]]; then
    ssh_load
fi

# Load pvenv
if [[ "${PVENV_HOME:-}" == "" ]]; then
    export PVENV_HOME="$HOME/.venvs"
    if cat /proc/1/sched | head -n 1 | grep -q systemd; then
        pvenv -n default use python3 --system-site-packages &>/dev/null
    fi
fi

# Update the path
path=('.' $path)
path=($HOME/.local/bin $path)
export PATH
export ZPROFILE_LOADED=true
