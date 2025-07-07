# shellcheck shell=zsh
# Logout commands {{{

# Kill ssh-agent and remove socket if it exists {{{

eval "$(ssh-agent -k &>/dev/null)"
if [[ -S "$SSH_AUTH_SOCK" ]]; then
  rm -f "$SSH_AUTH_SOCK"
  unset SSH_AUTH_SOCK
fi
# End Kill ssh-agent and remove socket if it exists }}}

# End Logout commands }}}
