# shellcheck shell=zsh
# Logout commands {{{

# Source shared functions {{{
source ~/.zshared || return
# End Source shared functions }}}

zdebug "Running ~/.zlogout"

# Kill ssh-agent and remove socket if it exists {{{
zdebug "Killing ssh-agent and deleting $SSH_AUTH_SOCK"
eval "$(ssh-agent -k &>/dev/null)"
if [[ -S "$SSH_AUTH_SOCK" ]]; then
  rm -f "$SSH_AUTH_SOCK"
  unset SSH_AUTH_SOCK
fi
# End Kill ssh-agent and remove socket if it exists }}}

# End Logout commands }}}
