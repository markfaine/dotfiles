# shellcheck shell=zsh
# Source helpers and perform single interactive unlock per login (stores token in tmpfs)

# Only run in interactive login shells
if [[ ! -o interactive ]]; then
  return
fi

if [[ -f "$HOME/.bw-login" ]]; then
  source "$HOME/.bw-login"
fi

# Retrieve and export personal secrets
dotfiles "default_personal"

# Load ssh
. .load-ssh
