# shellcheck shell=zsh
# Source helpers and perform single interactive unlock per login (stores token in tmpfs)

# Only run in interactive login shells
if [[ ! -o interactive ]]; then
  return
fi
