# Source helpers and clear session on logout (lock and remove tmpfs token)

# Only run on interactive logout shells
if [[ ! -o interactive ]]; then
  return
fi

if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "$SSH_AUTH_SOCK" ]; then
  rm -f "$SSH_AUTH_SOCK"
fi

# Clear the in-memory token (locks bw, removes file, signals other shells)
zdebug "Clearing Bitwarden session on logout"
unset BW_SESSION
clear
