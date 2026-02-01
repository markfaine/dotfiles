# shellcheck shell=zsh
# Source helpers and perform single interactive unlock per login (stores token in tmpfs)

# Only run in interactive login shells
if [[ ! -o interactive ]]; then
  return
fi

# Load ssh
if [[ -h ~/.load_ssh && -z "$_ssh_loaded" ]]; then
  # shellcheck source=/dev/null
  . ~/.load_ssh
  export _ssh_loaded=1
fi
