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
[ -x "$DIRENV" ] && eval "$("$DIRENV" export zsh)"

# Source fzf
FZF="$(command -v fzf)"
[ -x "$FZF" ] && source <(fzf --zsh)

# Fix an issue with zim init.zsh
# May no longer need this
#if ! grep -q "\$HOME" "$HOME/.zim/init.zsh"; then
#    sed -ri 's/\/home\/mfaine/\$HOME/g' "$HOME/.zim/init.zsh"
#fi

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

# Created by `pipx` on 2024-12-22 16:23:29
export PATH="$PATH:/home/mfaine/.local/bin"
