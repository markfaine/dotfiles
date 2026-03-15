# shellcheck shell=zsh source=/dev/null
# User configuration sourced by interactive shells
# ==============================================================================
# Shell Configuration Loading
# ==============================================================================

# Preferred editor keymap
bindkey -e

# Default for dotfiles directory is $HOME
export ZDOTDIR="$HOME"

# ==============================================================================
# Debug & Logging Configuration
# ==============================================================================
# Enable debug output (set to empty to disable)
ZSH_DEBUG="${ZSH_DEBUG:-}"

# Enable execution tracing (set to empty to disable)
ZSH_TRACE="${ZSH_TRACE:-}"

# ==============================================================================
# Logging Setup
# ==============================================================================
# Log file for debug output
ZLOG_DIR="$ZDOTDIR/.local/bin"
mkdir -p "$ZLOG_DIR"
export ZLOG_FILE="$ZLOG_DIR/zsh.log"

# Initialize log file (truncate on each session)
: >| "$ZLOG_FILE"

# ==============================================================================
# Setup fpath and autoload
# ==============================================================================
function _autoload_fpath(){
  local site_func_dir
  local funcs=("$@")

  site_func_dir="${XDG_DATA_HOME:-${ZDOTDIR:-$HOME}/.local/share}/zsh/site-functions"

  if [[ -d "$site_func_dir" ]]; then
    fpath=("$site_func_dir" $fpath)

    if (( $#funcs == 0 )); then
      # Default: Load everything in the directory
      autoload -Uz "$site_func_dir"/*(N:t)
    else
      # Specific: Validate each requested function before loading
      local func
      for func in "${funcs[@]}"; do
        if [[ -f "$site_func_dir/$func" ]]; then
          autoload -Uz "$func"
        else
          echo "zsh: function file not found: $site_func_dir/$func" >&2
        fi
      done
    fi
  fi
}

# ==============================================================================
# Znap Setup
# ==============================================================================
# Docs: https://github.com/marlonrichert/zsh-snap
ZNAP_HOME="${XDG_CONFIG_HOME:-${ZDOTDIR:-$HOME}/.config}/repos/znap"
zstyle ':znap:*' repos-dir "${ZNAP_HOME:h}" # parent dir
export ZNAP_HOME
_autoload_fpath
_download_znap || return
_load_znap || return

# ==============================================================================
# Znap Plugin Loading
# ==============================================================================
# Docs: https://github.com/marlonrichert/zsh-snap
_load_plugins || return

# ==============================================================================
# Auto suggestions
# ==============================================================================
# This one has to be last, loaded separately from _load_plugins function
znap source zsh-users/zsh-autosuggestions

# ==============================================================================
# SSH Identity Management
# ==============================================================================
# Load SSH identities into existing agent (assumes agent is already running via
# systemd, gpg-agent, keychain, or system default)

# Define key paths
CONFIG_KEY=$(grep -m1 "IdentityFile" "$ZDOTDIR/.ssh/config" 2>/dev/null | awk '{print $2}' | sed "s|^~|$HOME|")
DEFAULT_KEY="$HOME/.ssh/id_rsa"
SSH_ENV="$HOME/.ssh/agent.env"

if [ -f "${SSH_ENV}" ]; then
    zdebug ".zshrc: Sourcing $SSH_ENV"
    . "${SSH_ENV}" > /dev/null
    ps -ff | grep ${SSH_AGENT_PID} | grep ssh-agent > /dev/null || start_agent
else
    zdebug ".zshrc: Starting ssh-agent"
    start_agent
fi

# Load identities once per shell initialization
load_ssh_identities

# ==============================================================================
# Load Shell Aliases
# ==============================================================================
if [[ -f "$ZDOTDIR/.aliases" ]]; then
  zdebug ".zshrc: Loading shell aliases"
  # shellcheck source=/dev/null
  . "$ZDOTDIR/.aliases"
else
  zdebug ".zshrc: No aliases file found"
fi

# ==============================================================================
# Trash/Recycle Bin Management
# ==============================================================================
# Setup trash configuration
_setup_trash

# ==============================================================================
# Environment Detection
# ==============================================================================
_is_wsl

# ==============================================================================
# ZSH Module: Terminal Information
# ==============================================================================
_load_terminfo

# ==============================================================================
# ZSH Configuration: Keybindings
# ==============================================================================
_load_keybinds

# ==============================================================================
# File Sourcing: Aliases
# ==============================================================================
_load_aliases

# ==============================================================================
# File Sourcing: Directory Colors
# ==============================================================================
# Load zcolors, requires znap zcolors plugin
if [ -x /usr/bin/dircolors ]; then
  test -r "$ZDOTDIR/.dircolors" && eval "$(dircolors -b "$ZDOTDIR/.dircolors")" || eval "$(dircolors -b)"
fi

# ==============================================================================
# Load paths from ~/.paths
# ==============================================================================
# Load all PATH entries from .paths file
_load_paths

# ==============================================================================
# Theme-Agnostic Color Configuration
# ==============================================================================
# Load theme color settings that work with any kitty theme
# Uses terminal color indexes (0-15) instead of hardcoded hex colors
if [[ -f "$ZDOTDIR/.theme-colors" ]]; then
  # shellcheck source=/dev/null
  source "$ZDOTDIR/.theme-colors"
fi

# ==============================================================================
# Third-Party Tool Configuration: Ripgrep
# ==============================================================================
# Setup ripgrep configuration file path (only set if file exists)
if [[ -f "$ZDOTDIR/.ripgreprc" ]]; then
  export RIPGREP_CONFIG_PATH="$ZDOTDIR/.ripgreprc"
  zdebug ".zshrc: Ripgrep config loaded from $RIPGREP_CONFIG_PATH"
else
  zdebug ".zshrc: Ripgrep config not found at $ZDOTDIR/.ripgreprc (optional)"
fi

# ==============================================================================
# Activate Mise
# ==============================================================================
if (( $+commands[mise] )); then
  eval "$("${ZDOTDIR:-$HOME}/.local/bin/mise" activate zsh)"
fi

# ==============================================================================
# Activate Zoxide
# ==============================================================================
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# ==============================================================================
# User Extension Hooks
# ==============================================================================
# Allow users to add custom initialization without modifying this file
# Create ~/.zshrc.local for local customizations that won't be version controlled
if [[ -f "$ZDOTDIR/.zshrc.local" ]]; then
  zdebug ".zshrc: Loading local overrides from ~/.zshrc.local"
  # shellcheck source=/dev/null
  . "$ZDOTDIR/.zshrc.local"
fi

# ==============================================================================
# Activate fzf
# ==============================================================================
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi
