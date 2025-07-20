# ZSH Configuration {{{
# shellcheck shell=zsh
# User configuration sourced by interactive shells
# ## See https://zsh.sourceforge.io/Doc/Release/Options.html

# Misc Options {{{

# History Customization  {{{
# ## To read the history file every time history is called upon,
# ## as well as the functionality from inc_append_history
setopt share_history
# End History Customization  }}}

# Prompt for spelling correction of commands. {{{
# setopt CORRECT
# Customize spelling correction prompt.
# SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '
# End Prompt for spelling correction of commands. }}}

# It's annoying to always have to type a slash before tabbing {{{
setopt AUTO_PARAM_SLASH
# End It's annoying to always have to type a slash before tabbing }}}

# Remove path separator from WORDCHARS {{{
# This makes it so that / doen't count as part of a word in line editors
# For example, CTRL-W or ALT-Backspace
WORDCHARS=${WORDCHARS//[\/]}
# End Remove path separator from WORDCHARS }}}

# End Misc Options }}}

# Completion configuration {{{

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
zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
# End Better SSH/Rsync/SCP Autocomplete }}}

# Allow for autocomplete to be case insensitive {{{
# zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|?=** r:|?=**'
# End Allow for autocomplete to be case insensitive }}}

# End Completion configuration }}}

# ZSH Module configuration {{{

# Use ZSH complist module to create navigation in completion menu {{{
zmodload zsh/complist
# End Use ZSH complist module to create navigation in completion menu }}}

# ZSH Terminal Info module (dependency for zim) {{{
zmodload -F zsh/terminfo +p:terminfo
# End ZSH Terminal Info module (dependency for zim) }}}

# End ZSH Module configuration }}}

# Key mapping/remapping {{{

# Navigation Mappings {{{
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'l' vi-forward-char
# End Navigation Mappings }}}

# CTRL+X i will allow editing completion {{{
bindkey -M menuselect '^xi' vi-insert
# End CTRL+X i will allow editing completion }}}

# Set editor default keymap to emacs (`-e`) or vi (`-v`) {{{
bindkey -v
# End Set editor default keymap to emacs (`-e`) or vi (`-v`) }}}

# Possibly not needed with zim input module {{{
# Make home key go to the beginning of the line  {{{
#bindkey "^[[1~" beginning-of-line
# End Make home key go to the beginning of the line  }}}

# Make end key go to the end of the line {{{
#bindkey "^[[4~" end-of-line
# End Make end key go to the end of the line }}}

# Make delete key delete a character {{{
#bindkey "^[[3~" delete-char
# End Make delete key delete a character }}}
# End Possibly not needed with zim input module }}}

# Disable mappings for zle {{{
bindkey -e -r '^[x'
bindkey -a -r ':'
# End Disable mappings for zle }}}


# End Key mapping/remapping }}}

# Include Zim configuration {{{
# Zim is a zsh framework that simplifies some of the 
# boilerplate configuration for zsh
# https://zimfw.sh/
# By default it modifies the zsh file but I'd prefer it only
# source a separate file
# To disable zim comment out this section
if [[ -f ~/.zimsh ]]; then
    . ~/.zimsh
fi
# End Include Zim configuration }}}

# ## This disables the stupid "File exists!" warning on redirection {{{
# ## Something above is unsetting this so it has to be last
setopt CLOBBER
# ## This disables the stupid "File exists!" warning on redirection }}}

# Override options from zim zoxide module {{{
# Replace 'cd' command with zoxide
# Update weight of directory with every prompt
eval "$(zoxide init zsh --hook prompt --cmd cd)"
# End Override options from zim zoxide module }}}

# End Zsh Configuration  }}}
