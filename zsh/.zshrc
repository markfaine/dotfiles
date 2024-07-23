# Start configuration added by Zim install {{{
#
# User configuration sourced by interactive shells
#

# -----------------
# Zsh configuration
# -----------------

#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Prompt for spelling correction of commands.
#setopt CORRECT

# Customize spelling correction prompt.
#SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# -----------------
# Zim configuration
# -----------------

# Use degit instead of git as the default tool to install and update modules.
#zstyle ':zim:zmodule' use 'degit'

# --------------------
# Module configuration
# --------------------

#
# git
#

# Set a custom prefix for the generated aliases. The default prefix is 'G'.
#zstyle ':zim:git' aliases-prefix 'g'

#
# input
#

# Append `../` to your input for each `.` you type after an initial `..`
#zstyle ':zim:input' double-dot-expand yes

#
# termtitle
#

# Set a custom terminal title format using prompt expansion escape sequences.
# See http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Simple-Prompt-Escapes
# If none is provided, the default '%n@%m: %~' is used.
#zstyle ':zim:termtitle' format '%1~'
zstyle ':zim:termtitle' hooks 'preexec' 'precmd'
zstyle ':zim:termtitle:preexec' format '${${(A)=1}[1]}'
zstyle ':zim:termtitle:precmd'  format '%1~'

#
# zsh-autosuggestions
#

# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Set color for zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=23'

# Customize the style that the suggestions are shown with.
# See https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'

#
# zsh-syntax-highlighting
#

# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Customize the main highlighter styles.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md#how-to-tweak-it
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[comment]='fg=242'

# ------------------
# Initialize modules
# ------------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh

# ------------------------------
# Post-init module configuration
# ------------------------------

#
# zsh-history-substring-search
#

zmodload -F zsh/terminfo +p:terminfo
# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key
# }}} End configuration added by Zim install


# Completions

# group completions by type
zstyle ':completion:*' group-name ''

# Nicer completion listing
zstyle ':completion:*' file-list all

# Show colors in completion
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# // will become /
zstyle ':completion:*' squeeze-slashes true

# Match on options not dirs
zstyle ':completion:*' complete-options true

# Use complist to create navigation in completion menu
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# CTRL+X i will allow editing completion
bindkey -M menuselect '^xi' vi-insert

# It's annoying to always have to type a slash before tabbing
setopt AUTO_PARAM_SLASH

# Don't complete windows dirs
zstyle ':completion:*:*:ls:*:*' file-patterns '^/mnt'

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

# Use default venv
# requires pvenv installed in .zimrc
export PVENV_HOME="$HOME/.venvs"
if cat /proc/1/sched | head -n 1 | grep -q systemd; then
    pvenv -n default use python3 --system-site-packages &>/dev/null
fi

# Initialize pass
PASS="$(command -v pass)"
[ -x "$PASS" ] && "$PASS" show docker-credential-helpers/docker-pass-initialized-check &>/dev/null
