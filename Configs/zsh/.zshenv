# shellcheck shell=zsh
# Environment - loaded for all types of shell sessions {{{
# Source shared functions {{{
source ~/.zshared || return
# End Source shared functions }}}

# Fixes {{{
# Disable auto title for Microsoft Terminal auto title issue {{{
if [[ "${WSL_DISTRO_NAME:-}" != "" ]]; then
  zdebug "Windows terminal detected, disabling auto title"
  export DISABLE_AUTO_TITLE=true
fi
# End Disable auto title for Microsoft Terminal auto title issue }}}

# WSL all shells are login shells {{{
# In WSL there doesn't seem to be a 'login-shell' concept
# all shells seem to be login shells, as far as I can tell.
# The below makes standard linux practice of adding only login
# shell configuration to .zprofile work in wsl
# Doesn't affect any other linux based distro
if [[ "${WSL_DISTRO_NAME:-}" != "" ]]; then
  if [[ "${ZPROFILE_LOADED:-}" == "" ]]; then
    . ~/.zprofile
  fi
fi
# End WSL all shells are login shells }}}
# End Fixes }}}

# Common User Preference Environment Variables {{{

# Pager Configuration {{{
# export PAGER=bat
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
if [[ "${WSL_DISTRO_NAME:-}" == "" ]]; then
  zdebug "Loading SSL keys from yubikey"
  ssh_load
fi
# End Function to load ssh-agent from yubikey }}}

# Doppler scope {{{
doppler-scope() {
  perform_reset=$1
  if [ "$perform_reset" = "reset" ]; then
    unset D_SCOPE
    unset DOPPLER_TOKEN
  else
    export D_SCOPE="$(find ~/doppler/scopes -maxdepth 2 | fzf)"
    export DOPPLER_TOKEN=$(doppler --scope "$D_SCOPE" configure get token --plain)
  fi
}
# End Doppler scope }}}

# Add ansible-language-server to path {{{
path=($path "$HOME/.local/share/nvim/mason/packages/ansible-language-server/node_modules/@ansible/ansible-language-server/bin")
export PATH
# End Add ansible-language-server to path }}}

# End Environment - loaded for all types of shell sessions }}}
