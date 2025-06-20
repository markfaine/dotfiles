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

# ## To read the history file every time history is called upon,
# ## as well as the functionality from inc_append_history
setopt share_history

#
# Input/output
#

zstyle ':completion:*' group-name ''

# Nicer completion listing
zstyle ':completion:*' file-list all

# Show colors in completion
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# // will become /
zstyle ':completion:*' squeeze-slashes true

# Match on options not dirs
zstyle ':completion:*' complete-options true

# Better SSH/Rsync/SCP Autocomplete
#zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
#zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
#zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# Allow for autocomplete to be case insensitive
#zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|?=** r:|?=**'

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

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Prompt for spelling correction of commands.
setopt CORRECT

# Customize spelling correction prompt.
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# Include Zim configuration
if [[ -f ~/.zimsh ]]; then
    . ~/.zimsh
fi

# Completions
# group completions by type
#
# ## This disables the stupid "File exists!" warning on redirection
# ## Something above is unsetting this so it has to be last
setopt CLOBBER

# Load zprofile if not already loaded
if [[ "${ZPROFILE_LOADED:-}" == "" ]]; then
    . ~/.zprofile
fi

# Actiate Mise
eval "$(mise activate zsh)"
