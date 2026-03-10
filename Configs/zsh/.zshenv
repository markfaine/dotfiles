# shellcheck shell=zsh
# Environment - loaded for all types of shell sessions
# Source shared functions

# Reset module tracking flags for this shell session
unset _theme_colors_loaded _zshared_loaded

# ==============================================================================
# Editor & Pager Configuration
# ==============================================================================
# Primary editor for environment
export EDITOR="nvim"

# Pager for various commands (bat provides syntax highlighting)
export PAGER="bat"

# Pager for git commands (use default PAGER)
export GIT_PAGER="$PAGER"

# Pager for man pages (use default PAGER)
export MANPAGER="$PAGER"

# Pager for systemd commands
export SYSTEMD_PAGER="$PAGER"

# SSH authentication prompt program (for passphrase input)
# Only set if ssh-askpass is available
if command -v ssh-askpass &>/dev/null; then
  export SSH_ASKPASS="$(command -v ssh-askpass)"
fi

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
# File Operations
# ==============================================================================
# Allow history entries to overwrite existing files
export HIST_ALLOW_CLOBBER="true"

# ==============================================================================
# Shell History Configuration
# ==============================================================================
# History file location
export HISTFILE="$HOME/.zsh_history"

# Number of history lines to keep in memory
export HISTSIZE="5000"

# Number of history lines to save to file
export SAVEHIST="5000"

# Append history incrementally to HISTFILE
export APPEND_HISTORY="true"

# Enable ! history expansion
export BANG_HISTORY="true"

# Skip duplicate commands when expanding history
export HIST_IGNORE_ALL_DUPS="true"

# Don't save commands that start with a space
export HIST_IGNORE_SPACE="true"

# Don't store function definitions in history
export HIST_NO_FUNCTIONS="true"

# Commands to ignore when recording history (wildcard patterns)
export HISTORY_IGNORE="(ls*|ll*|pwd|exit|cd*|vi|vim)"

# ==============================================================================
# Terminal & Display
# ==============================================================================
# Disable automatic terminal title updates by shell
export DISABLE_AUTO_TITLE="false"

# Enable colored output for systemd commands
export SYSTEMD_COLORS="true"

# Flag for systemd pager (secure mode)
export SYSTEMD_PAGERSECURE="true"

# ==============================================================================
# System Configuration
# ==============================================================================
# Timezone for time-related functions
export TZ="America/Chicago"

# ==============================================================================
# Debug & Logging Configuration
# ==============================================================================
# Enable debug output (set to empty to disable)
ZSH_DEBUG="${ZSH_DEBUG:-1}"

# Enable execution tracing (set to empty to disable)
ZSH_TRACE="${ZSH_TRACE:-}"

# ==============================================================================
# Shell Options
# ==============================================================================
# Clobber option: allow overwriting files with >
setopt clobber

# ==============================================================================
# Logging Setup
# ==============================================================================
# Log file for debug output
export ZLOG_FILE="$HOME/.zshlog"

# Initialize log file (truncate on each session)
: >| "$HOME/.zshlog"

function zdebug() {
  if [[ -n $ZSH_DEBUG ]]; then
    echo "DEBUG: $*" >>"$ZLOG_FILE"
  fi
}

function ztrace() {
  if [[ -n $ZSH_TRACE ]]; then
    set -x
  fi
}

# ==============================================================================
# Environment Detection
# ==============================================================================
# Export a variable if this is WSL
function _is_wsl(){
  if grep -q Microsoft /proc/version; then
    zdebug ".zshenv: Session is in WSL"
    export IS_WSL=1
  fi
}
_is_wsl

# ==============================================================================
# ZSH Module configuration (built-in) {{{
# See: https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html

# ==============================================================================
# ZSH Module: Completion
# ==============================================================================
# Load zsh completion module and configure globbing
# Uses fast compinit cache to avoid slow initialization on every shell startup

# Add home directory to fpath for custom completions (e.g., _tmuxinator)
fpath=(~/ $fpath)

function _load_complist(){
  zdebug ".zshenv: Loading zsh/complist"

  # Fail fast if module not available
  zmodload zsh/complist || { zdebug ".zshenv: Failed to load zsh/complist"; return 1; }

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
# ZSH Module: Terminal Information
# ==============================================================================
# Load zsh terminal info module (dependency for zim)
function _load_terminfo(){
  zdebug ".zshenv: Loading zsh/terminfo"
  # Fail fast if module not available
  zmodload -F zsh/terminfo +p:terminfo || { zdebug ".zshenv: Failed to load zsh/terminfo"; return 1; }
}
_load_terminfo

# TODO: formalize this in the configuration and make sure it's not incompatible
# with other options.
bindkey -e

# ==============================================================================
# ZSH Configuration: Keybindings
# ==============================================================================
# Configure vim-style keybindings in completion menu
function _load_keybinds(){
  ## Use vim keys in tab complete menu:
  bindkey -M menuselect 'h' vi-backward-char
  bindkey -M menuselect 'j' vi-down-line-or-history
  bindkey -M menuselect 'k' vi-up-line-or-history
  bindkey -M menuselect 'l' vi-forward-char

  # Fix backspace bug when switching modes
  bindkey "^?" backward-delete-char

}
_load_keybinds

# TODO: Remove or fix this, it interferes with SSH kex_exchange banner
# ==============================================================================
# Terminal Customization: Cursor
# ==============================================================================
# Configure beam cursor for visual feedback
function _load_cursor(){
  echo -ne '\e[5 q' # Use beam shape cursor on startup.
  precmd() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.
}
_load_cursor

# ==============================================================================
# Third-Party Tool Configuration: Ripgrep
# ==============================================================================
# Setup ripgrep configuration file path (only set if file exists)
if [[ -f "$HOME/.ripgreprc" ]]; then
  export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
  zdebug ".zshenv: Ripgrep config loaded from $RIPGREP_CONFIG_PATH"
else
  zdebug ".zshenv: Ripgrep config not found at $HOME/.ripgreprc (optional)"
fi

# ==============================================================================
# File Sourcing: Aliases
# ==============================================================================
# Load user command aliases
function _load_aliases(){
  ZALIASES="$HOME/.aliases"
  if [[ -e "$ZALIASES" ]]; then
    #shellcheck source=/dev/null
    . "$ZALIASES"
    zdebug ".zshenv: Sourcing $ZALIASES"
  else
    zdebug ".zshenv: Failed to source $ZALIASES"
  fi
}
_load_aliases

# ==============================================================================
# File Sourcing: Directory Colors
# ==============================================================================
# Load zcolors, requires znap zcolors plugin
function _load_zcolors(){
  if (( ! $+commands[znap] )) && ! typeset -f znap > /dev/null 2>&1; then
    zdebug ".zshenv: Skipping zcolors - znap not available"
    return
  fi
  znap eval LS_COLORS 'dircolors -b LS_COLORS'
  zstyle \":completion:*:default\" list-colors \"${(s.:.)LS_COLORS}\"
  znap eval zcolors "zcolors ${(q)LS_COLORS}"
  zdebug ".zshenv: Setting up dircolors solarized"
}
if [ -x /usr/bin/dircolors ]; then
  test -r "$HOME/.dircolors" && eval "$(dircolors -b "$HOME/.dircolors")" || eval "$(dircolors -b)"
fi
if [[ ! -f "$HOME/.zsh-dircolors.config" ]]; then
  _load_zcolors
fi

# ==============================================================================
# Python/UV: Environment Configuration
# ==============================================================================
# Set default virtual environment
export UV_PROJECT_ENVIRONMENT="$HOME/.venv"

# ==============================================================================
# PATH Management
# ==============================================================================
# Normalize path entries from .paths (trim whitespace/quotes and expand $HOME/~)
function _normalize_path_entry() {
  local raw="$1"

  # Trim leading and trailing whitespace
  raw="${raw#"${raw%%[![:space:]]*}"}"
  raw="${raw%"${raw##*[![:space:]]}"}"

  # Strip optional surrounding quotes from CSV values
  raw="${raw#\"}"
  raw="${raw%\"}"
  raw="${raw#\'}"
  raw="${raw%\'}"

  # Expand common home-directory forms used in config
  raw="${raw//\$HOME/$HOME}"
  if [[ "$raw" == "~"* ]]; then
    raw="${raw/#\~/$HOME}"
  fi

  printf '%s' "$raw"
}

# Append a directory to PATH (checks if directory exists)
function _append_to_path() {
  local dir normalized realdir
  dir="$1"
  normalized="$(_normalize_path_entry "$dir")"
  [[ -n "$normalized" ]] || return
  realdir="$(readlink -f "$normalized" 2>/dev/null || true)"
  [[ -d "$realdir" ]] || return
  path=($path "$normalized")
}

# Prepend a directory to PATH (checks if directory exists)
function _prepend_to_path() {
  local dir normalized realdir
  dir="$1"
  normalized="$(_normalize_path_entry "$dir")"
  [[ -n "$normalized" ]] || return
  realdir="$(readlink -f "$normalized" 2>/dev/null || true)"
  [[ -d "$realdir" ]] || return
  path=("$normalized" $path)
}

# Read PATH entries from file (comma-separated format)
# File format: append_dir,prepend_dir (empty fields are skipped, # lines are comments)
function _add_to_path() {
    paths_file="${1:-$HOME/.paths}"
    while IFS=',' read -r append prepend; do
        line="${append}${prepend}"
        [[ -z $line ]] && continue
        [[ "$line" = \#* ]] && continue
        if [[ "${append:-}" != "" ]]; then
          zdebug ".zshenv: Appending $append to PATH"
          _append_to_path "$append"
        fi
        if [[ "${prepend:-}" != "" ]]; then
          zdebug ".zshenv: Prepending $prepend to PATH"
          _prepend_to_path "$prepend"
        fi
    done < <(tac "$paths_file")
}

# Load all PATH entries from .paths file
function _load_paths(){
  ZPATHS="$HOME/.paths"
  if [[ -f "$ZPATHS" ]]; then
    _add_to_path
    export PATH
    zdebug ".zshenv: Adding paths from $ZPATHS"
  else
    zdebug ".zshenv: Failed to add paths from $ZPATHS"
  fi
  zdebug ".zshenv: Deduping \$PATH"
  typeset -U PATH
}
_load_paths

# ==============================================================================
# NVM: Load nvm znap plugin
# ==============================================================================
NVM_DIR="$HOME/.nvm"
export NVM_DIR
# Install nvm
export NVM_COMPLETION=true
export NVM_LAZY_LOAD=true
znap clone lukechilds/zsh-nvm
znap source lukechilds/zsh-nvm
if [[ ! -d "$NVM_DIR" && ! command -v npm &>/dev/null; then
  nvm install node &>/dev/null
fi

# ==============================================================================
# Mise: Enable mise if npm is available
# ==============================================================================
if command -v npm &>/dev/null; then
  znap clone joke/zim-mise
  znap source joke/zim-mise
else
  zdebug "Could not activate mise, npm is not available!"
fi

# ==============================================================================
# File Sourcing: Shared Functions
# ==============================================================================
# Load shared shell functions from .zshared file
function _load_zhared(){
  zhared="$HOME/.zshared"
  if [[ -f "$zhared" ]]; then
    #shellcheck source=/dev/null
    . "$zhared"
    zdebug ".zshenv: Sourcing $zhared"
  else
    zdebug ".zshenv: Failed to source $zhared"
  fi
}
if [[ -z "$_zshared_loaded" ]]; then
  _load_zhared
fi
