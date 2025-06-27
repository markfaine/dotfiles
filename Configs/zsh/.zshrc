# ZSH Configuration {{{
# shellcheck shell=zsh
# User configuration sourced by interactive shells

# ## See https://zsh.sourceforge.io/Doc/Release/Options.html
# ## Seems ignoring in the current shell session isn't possible
# ## but we can prevent saving to the history file.

# History Customization  {{{
# ## To read the history file every time history is called upon,
# ## as well as the functionality from inc_append_history
setopt share_history
# End History Customization  }}}

# Group the different type of completion matches under their descriptions  {{{
zstyle ':completion:*' group-name ''
# End Group the different type of completion matches under their descriptions  }}}

# Display the list of files and folder matched with more details  {{{
zstyle ':completion:*' file-list all
# End Display the list of files and folder matched with more details  }}}

# Show colors in completion {{{
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# End Show colors in completion }}}

# Squeeze slashes in matches so // will become / {{{
zstyle ':completion:*' squeeze-slashes true
# End Squeeze slashes in matches so // will become / }}}

# Match on options not dirs {{{
zstyle ':completion:*' complete-options true
# End Match on options not dirs }}}

# Better SSH/Rsync/SCP Autocomplete {{{
#zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
#zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
#zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
# End Better SSH/Rsync/SCP Autocomplete }}}

# Allow for autocomplete to be case insensitive {{{
# zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|?=** r:|?=**'
# End Allow for autocomplete to be case insensitive }}}

# Use complist to create navigation in completion menu {{{
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'l' vi-forward-char
# End Use complist to create navigation in completion menu }}}

# CTRL+X i will allow editing completion {{{
bindkey -M menuselect '^xi' vi-insert
# End CTRL+X i will allow editing completion }}}


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
# End Zsh Configuration  }}}
