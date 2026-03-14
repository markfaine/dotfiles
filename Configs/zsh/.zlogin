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

# Ensure .zlogin never causes shell initialization to fail
return 0 2>/dev/null || true
