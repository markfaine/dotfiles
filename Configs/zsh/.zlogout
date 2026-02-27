# shellcheck shell=zsh
# Logout shell cleanup (runs once when exiting login session)
# Cleans up session state and credentials

# ==============================================================================
# Execution Guard
# ==============================================================================
# Only run on interactive logout shells
if [[ ! -o interactive ]]; then
  return
fi

# ==============================================================================
# SSH Agent Cleanup
# ==============================================================================
# Remove SSH agent socket on logout
if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "$SSH_AUTH_SOCK" ]; then
  rm -f "$SSH_AUTH_SOCK"
fi

# ==============================================================================
# Credential Cleanup
# ==============================================================================
# Clear Bitwarden session on logout
zdebug "Clearing Bitwarden session on logout"
unset BW_SESSION
clear
