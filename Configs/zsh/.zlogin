# shellcheck shell=zsh
# Login shell initialization (runs once per login session)
# Performs setup tasks that should only run once at login

# ==============================================================================
# Execution Guard
# ==============================================================================
# Only run in interactive login shells
# Use || true to ensure this never causes shell to exit
if [[ ! -o interactive ]]; then
  return 0 2>/dev/null || true
fi

# ==============================================================================
# SSH Agent Initialization
# ==============================================================================
# Initialize SSH agent and load keys for this session
# Wrap in conditional to prevent any failures from propagating
if [[ -h ~/.load_ssh ]] && [[ -z "${_ssh_loaded:-}" ]]; then
  # shellcheck source=/dev/null
  { source ~/.load_ssh } 2>/dev/null || true
  export _ssh_loaded=1
fi

# Ensure .zlogin never causes shell initialization to fail
return 0 2>/dev/null || true
