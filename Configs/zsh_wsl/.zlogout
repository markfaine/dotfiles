# Source helpers and clear session on logout (lock and remove tmpfs token)

# Only run on interactive logout shells
if [[ ! -o interactive ]]; then
  return
fi
clear
