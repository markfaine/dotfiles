# shellcheck shell=zsh source=/dev/null
# User configuration sourced by interactive shells
# ==============================================================================
# Shell Configuration Loading
# ==============================================================================

# Preferred editor keymap
bindkey -e

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
ZLOG_DIR="$HOME/.local/bin"
mkdir -p "$ZLOG_DIR"
export ZLOG_FILE="$ZLOG_DIR/zsh.log"

# Initialize log file (truncate on each session)
: >| "$ZLOG_FILE"

# ==============================================================================
# Setup fpath and autoload
# ==============================================================================
local site_func_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
if [[ -d "$site_func_dir" ]]; then
  fpath=("$site_func_dir" $fpath)
  autoload -Uz "$site_func_dir"/*(N)
fi

# ==============================================================================
# Znap Setup & Plugin Loading
# ==============================================================================
# Docs: https://github.com/marlonrichert/zsh-snap
ZNAP_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/repos/znap"
zdebug ".znaprc: ZNAP_HOME: $ZNAP_HOME"
zstyle ':znap:*' "$ZNAP_HOME"
export ZNAP_HOME
_download_znap || return
_load_znap || return
_load_plugins || return

# ==============================================================================
# ZSH Module: Completion
# ==============================================================================
# Load zsh completion module and configure globbing
# Uses fast compinit cache to avoid slow initialization on every shell startup
function _load_complist(){
  zdebug ".zshrc: Loading zsh/complist"

  # Fail fast if module not available
  zmodload zsh/complist || { zdebug ".zshrc: Failed to load zsh/complist"; return 1; }

  # Use cached completions for speed (only regenerate if needed)
  autoload -U compinit
  if [[ -z "$COMPDUMP" ]]; then
    COMPDUMP="$HOME/.cache/zsh/zcompdump"
    [[ ! -d "${COMPDUMP%/*}" ]] && mkdir -p "${COMPDUMP%/*}"
  fi
  compinit -d "$COMPDUMP" -C
  _comp_options+=(globdots)    # Include hidden files.
}
_load_complist

# ==============================================================================
# SSH Identity Management
# ==============================================================================
# Load SSH identities into existing agent (assumes agent is already running via
# systemd, gpg-agent, keychain, or system default)

# Define key paths
CONFIG_KEY=$(grep -m1 "IdentityFile" "$HOME/.ssh/config" 2>/dev/null | awk '{print $2}' | sed "s|^~|$HOME|")
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
if [[ -f "$HOME/.aliases" ]]; then
  zdebug ".zshrc: Loading shell aliases"
  # shellcheck source=/dev/null
  . "$HOME/.aliases"
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
  test -r "$HOME/.dircolors" && eval "$(dircolors -b "$HOME/.dircolors")" || eval "$(dircolors -b)"
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
if [[ -f "$HOME/.theme-colors" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.theme-colors"
fi

# ==============================================================================
# Third-Party Tool Configuration: Ripgrep
# ==============================================================================
# Setup ripgrep configuration file path (only set if file exists)
if [[ -f "$HOME/.ripgreprc" ]]; then
  export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
  zdebug ".zshrc: Ripgrep config loaded from $RIPGREP_CONFIG_PATH"
else
  zdebug ".zshrc: Ripgrep config not found at $HOME/.ripgreprc (optional)"
fi

# ==============================================================================
# Activate Mise
# ==============================================================================
eval "$(mise activate zsh)"

# ==============================================================================
# Activate Zoxide
# ==============================================================================
eval "$(zoxide init zsh)"

# ==============================================================================
# User Extension Hooks
# ==============================================================================
# Allow users to add custom initialization without modifying this file
# Create ~/.zshrc.local for local customizations that won't be version controlled
if [[ -f "$HOME/.zshrc.local" ]]; then
  zdebug ".zshrc: Loading local overrides from ~/.zshrc.local"
  # shellcheck source=/dev/null
  . "$HOME/.zshrc.local"
fi
