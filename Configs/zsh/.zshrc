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
ZLOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
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
    # Stale compiled function files can load outdated logic and break ZLE wrappers.
    find "$site_func_dir" -maxdepth 1 -type f -name '*.zwc' -delete 2>/dev/null || true

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

# Load prompt
znap prompt sindresorhus/pure

# ==============================================================================
# Smart URL Pasting
# ==============================================================================
# Load the bracketed-paste-magic and url-quote-magic functions
autoload -Uz bracketed-paste-magic url-quote-magic
zle -N bracketed-paste bracketed-paste-magic
zstyle :bracketed-paste-magic filter-active url-quote-magic


# ==============================================================================
# Double dot expansion
# ==============================================================================
# Also see: ~/.zshenv for bindkeys
zle -N _double_dot_expand

# ==============================================================================
# Activate Mise
# ==============================================================================
if (( $+commands[mise] )); then
  znap eval mise 'mise activate zsh'
fi

# ==============================================================================
# Znap Plugin Loading
# ==============================================================================
# Docs: https://github.com/marlonrichert/zsh-snap
_load_plugins \
  "MichaelAquilina/zsh-you-should-use" \
  "MrXcitement/zsh-bat" \
  "marlonrichert/zcolors" \
  "thetic/extract,,,extract" \
  "zap-zsh/sudo" \
  "laggardkernel/zsh-thefuck,,,tf" || return

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
# Activate Zoxide
# ==============================================================================
if (( $+commands[zoxide] )); then
  znap eval zoxide 'zoxide init zsh'
fi

# ==============================================================================
# Activate fzf
# ==============================================================================
if (( $+commands[fzf] )); then
  znap eval fzf-init 'fzf --zsh'
fi

# ==============================================================================
# Auto suggestions
# ==============================================================================
# Keep this block near the end so ZLE widget wrappers are applied once, in order.
# Load order here avoids autosuggestions/pure recursion on Enter.

_load_plugins "zsh-users/zsh-completions,,src" || return
_load_plugins "zsh-users/zsh-syntax-highlighting" || return
_load_plugins "zsh-users/zsh-autosuggestions" || return
_load_plugins "zsh-users/zsh-history-substring-search" || return
_load_plugins "sindresorhus/pure,,." || return

# ==============================================================================
# Keybindings
# ==============================================================================
# Assumes Emacs mode bindkey -e # set in ~/.zshrc

# Standard Keys using Terminfo
bindkey "${terminfo[kbs]}"    backward-delete-char   # Backspace
bindkey "${terminfo[kdch1]}"  delete-char            # Delete
bindkey "${terminfo[kich1]}"  overwrite-mode         # Insert
bindkey "${terminfo[khome]}"  beginning-of-line      # Home
bindkey "${terminfo[kend]}"   end-of-line            # End
bindkey "${terminfo[kpp]}"    up-line-or-history     # PageUp
bindkey "${terminfo[knp]}"    down-line-or-history   # PageDown
bindkey "${terminfo[kcuu1]}"  up-line-or-history     # Up Arrow
bindkey "${terminfo[kcud1]}"  down-line-or-history   # Down Arrow
bindkey "${terminfo[kcub1]}"  backward-char          # Left Arrow
bindkey "${terminfo[kcuf1]}"  forward-char           # Right Arrow
bindkey "${terminfo[kcbt]}"   reverse-menu-complete  # Shift-Tab

# Terminal-Specific Fixes (Ctrl + Arrows for Word Jumping)
# These codes work across Kitty, Windows Terminal, and Konsole
bindkey '^[[1;5C' forward-word       # Ctrl+Right
bindkey '^[[1;5D' backward-word      # Ctrl+Left

# Open current command in EDITOR (Ctrl-X, Ctrl-E)
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# Double dot expansion
# Bind the dot key to the widget
bindkey "." _double_dot_expand

# Optional: Ensure the expansion doesn't break normal completion
bindkey -M isearch "." self-insert

# Accept suggestion with right arrow
#bindkey '^[[C' autosuggest-accept

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
