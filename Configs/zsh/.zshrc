# ZSH Configuration {{{

# shellcheck shell=zsh
# User configuration sourced by interactive shells
# ## See https://zsh.sourceforge.io/Doc/Release/Options.html

# Source shared functions {{{
export ZSH_DEBUG=1
source ~/.zshared || return
zdebug "Sourcing ~/.zshrc"
# End Source shared functions }}}

# ZSH Module configuration (built-in) {{{
# See: https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html

# Use ZSH complist module to create navigation in completion menu {{{
zdebug "Loading zsh/complist"
zmodload zsh/complist
autoload -U compinit
compinit
_comp_options+=(globdots)		# Include hidden files.
# End Use ZSH complist module to create navigation in completion menu }}}

# ZSH Terminal Info module (dependency for zim) {{{
zdebug "Loading zsh/terminfo"
zmodload -F zsh/terminfo +p:terminfo
# End ZSH Terminal Info module (dependency for zim) }}}

# Include znap configuration {{{
if [[ -f ~/.znaprc ]]; then
  zdebug "~/.znaprc exists!"
  . ~/.znaprc
else
  zdebug "~/.znaprc was not found!"
fi
# End Include znap configuration }}}

# End ZSH Module configuration }}}

# Key mapping/remapping {{{
# CTRL+X i will allow editing completion {{{
zdebug "Mapping ctrl-x to allow editing completions"
bindkey -M menuselect '^xi' vi-insert
# End CTRL+X i will allow editing completion }}}

# Set editor default keymap to emacs (`-e`) or vi (`-v`) {{{
zdebug "Set editor to vi style command line editing"
bindkey -v
# End Set editor default keymap to emacs (`-e`) or vi (`-v`) }}}

# vi mode mappings for line editor{{{
bindkey -v
export KEYTIMEOUT=1

# Enable searching through history
bindkey '^R' history-incremental-pattern-search-backward

# Edit line in vim buffer ctrl-v
autoload edit-command-line; zle -N edit-command-line
bindkey '^v' edit-command-line

# Enter vim buffer from normal mode
autoload -U edit-command-line && zle -N edit-command-line && bindkey -M vicmd "^v" edit-command-line

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# Fix backspace bug when switching modes
bindkey "^?" backward-delete-char

# End vi mode mappings for line editor{{{


# End Key mapping/remapping }}}

# Change cursor for different vi modes in line editor {{{
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

# ci", ci', ci`, di", etc
autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
  for c in {a,i}{\',\",\`}; do
    bindkey -M $m $c select-quoted
  done
done

# ci{, ci(, ci<, di{, etc
autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $m $c select-bracketed
  done
done

zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init

echo -ne '\e[5 q' # Use beam shape cursor on startup.
precmd() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# End Change cursor for different vi modes in line editor }}}

# Dedup the path {{{
zdebug "Deduping \$PATH"
#typeset -U PATH
# End Dedup the path }}}

# Export path to child processes
zdebug "Exporting PATH: $PATH"
export PATH


alias oldvim='NVIM_APPNAME=old-vim nvim'
alias vi=nvim
alias vim=nvim
# End Zsh Configuration  }}}

# Add this here for now
eval "$(gh copilot alias -- zsh)"

path=('.' $path)
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.doppler/bin:$PATH"
