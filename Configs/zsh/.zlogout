# shellcheck shell=zsh
# Logout shell cleanup (runs once when exiting login session)
# Cleans up session state and credentials

# ==============================================================================
# Execution Guard
# ==============================================================================
# Only run on interactive logout shells
if [[ ! -o interactive ]]; then
  return 0 2>/dev/null || exit 0
fi
