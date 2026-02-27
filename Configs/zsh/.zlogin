# shellcheck shell=zsh
# Login shell initialization (runs once per login session)
# Performs setup tasks that should only run once at login

# ==============================================================================
# Execution Guard
# ==============================================================================
# Only run in interactive login shells
if [[ ! -o interactive ]]; then
  return
fi

# ==============================================================================
# SSH Agent Initialization
# ==============================================================================
# Initialize SSH agent and load keys for this session
if [[ -h ~/.load_ssh && -z "$_ssh_loaded" ]]; then
  # shellcheck source=/dev/null
  . ~/.load_ssh
  _ssh_loaded=1
fi
