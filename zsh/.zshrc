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

# ## History customization
# ## See https://zsh.sourceforge.io/Doc/Release/Options.html
# ## Seems ignoring in the current shell session isn't possible
# ## but we can prevent saving to the history file.
touch ~/.zsh_history
export HIST_IGNORE_ALL_DUPS
export HISTFILE=~/.zsh_history
export HISTSIZE=1000
export SAVEHIST=1000
export APPEND_HISTORY=true
export BANG_HISTORY=true
export HIST_ALLOW_CLOBBER=true
export HIST_IGNORE_SPACE=true
export HIST_NO_FUNCTIONS=true
export HIST_NO_STORE=true
export HISTORY_IGNORE="(ls*|ll*|pwd|exit|cd*|vi|vim)"

# ## To read the history file every time history is called upon,
# ## as well as the functionality from inc_append_history
setopt share_history

#
# Input/output
#

# ## This disables the stupid "File exists!" warning on redirection
setopt clobber

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
zstyle ':zim:git' aliases-prefix 'g'

#
# input
#

# Append `../` to your input for each `.` you type after an initial `..`
zstyle ':zim:input' double-dot-expand yes

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

# If this is the only instance of zsh, source zprofile
if [[ "$(pgrep -fc "/usr/bin/zsh")" -eq 1 ]]; then
    . ~/.zprofile
fi  
