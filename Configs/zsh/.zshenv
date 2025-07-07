# shellcheck shell=zsh
# Environment - loaded for all types of shell sessions {{{

# Dependencies for other tools {{{

# Disable system-wide compinit, let zim handle completion  {{{
# Zim requires this to be set
skip_global_compinit=1
# End Disable system-wide compinit, let zim handle completion  }}}

# End Dependencies for other tools }}}

# PATH configuration {{{

# Dedup the path {{{
typeset -U PATH
# End Dedup the path }}}

# Add Mason bin directory to path {{{
# mason is a package manager used by neovim,
# it installs packages to the path below.
path=($path "$HOME/.local/share/nvim/mason/bin")
# End Add Mason bin directory to path }}}

# Add user bin directory to the path {{{
# See: ~/.local/bin
path=($path $HOME/.local/bin)
# End Add user bin directory to the path }}}

# Add dot to path {{{
path=(. $path)
# End Add dot to path }}}

# Export PATH so it will be inherited by child processes {{{
export PATH
# End Export PATH so it will be inherited by child processes }}}

# End PATH configuration }}}

# Source aliases {{{
if [[ -f "$HOME/.aliases" ]]; then
  . "$HOME/.aliases"
fi
# End Source aliases }}}

# Setup trash folder if it doesn't exist {{{
if [[ ! -d "$HOME/.Trash" ]]; then
  mkdir -p "$HOME/.Trash"
fi
# End Setup trash folder if it doesn't exist }}}

# Fixes {{{
# Disable auto title for Microsoft Terminal auto title issue {{{
if [[ "${WT_SESSION:-}" != "" ]]; then
  export DISABLE_AUTO_TITLE=true
fi
# End Disable auto title for Microsoft Terminal auto title issue }}}

# Set colorterm, work-around for tmux issue with true color {{{
export COLORTERM=truecolor
# Set colorterm, work-around for tmux issue with true color }}}

# WSL all shells are login shells {{{
# In WSL there doesn't seem to be a 'login-shell' concept
# all shells seem to be login shells, as far as I can tell.
# This makes standard linux practice of adding only login
# shell configuration to .zprofile work in wsl
# Doesn't affect any other linux based distro
if [[ "${WT_SESSION:-}" != "" ]]; then
  if [[ "${ZPROFILE_LOADED:-}" == "" ]]; then
    . ~/.zprofile
  fi
fi
# End WSL all shells are login shells }}}
# End Fixes }}}

# Common User Preference Environment Variables {{{

# Editor Configuration {{{
export EDITOR=nvim
# End Editor Configuration }}}

# Pager Configuration {{{
export PAGER=bat
export MANPAGER=$PAGER
export GIT_PAGER=$PAGER
export SYSTEMD_PAGER=$PAGER
export SYSTEMD_PAGERSECURE=true
export SYSTEMD_COLORS=true
# End Pager Configuration }}}

# Ripgrep config path {{{
RIPGREP_CONFIG_PATH=~/.ripgreprc
export RIPGREP_CONFIG_PATH
# End Common User Preference Environment Variables }}}

# Git environment variables {{{
# Don't verify SSL certificates {{{
export GIT_SSL_NO_VERIFY=true
# End Don't verify SSL certificates }}}
# End Git environment variables }}}

# Function to load ssh-agent from yubikey {{{
function ssh_load() {
  eval "$(
    ssh-agent -s
    SSH_ASKPASS=$SSH_ASKPASS
  )"
  ssh-add -K || true
}
# End Function to load ssh-agent from yubikey }}}

# Load ssh-agent with keys from yubikey, if not already loaded {{{
if [[ "${SSH_AUTH_SOCK:-}" == "" ]]; then
  ssh_load
fi
# End Load ssh-agent if not already loaded }}}

# End Environment - loaded for all types of shell sessions }}}
