# ==============================================================================
# Environment Settings (zimfw/environment)
# ==============================================================================

# History file path override (defaults to ${ZDOTDIR:-${HOME}}/.zhistory if unset)
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/.zsh_history"

# Performs cd to a directory if the typed command is invalid, but is a directory.
AUTO_CD=true

# Makes cd push the old directory to the directory stack.
AUTO_PUSHD=true

# Does not print the working directory after a cd.
CD_SILENT=true

# Does not push multiple copies of the same directory to the stack.
PUSHD_IGNORE_DUPS=true

# Does not print the directory stack after pushd or popd.
PUSHD_SILENT=true

# Has pushd without arguments act like `pushd ${HOME}`.
PUSHD_TO_HOME=true

# ==============================================================================
# Expansion and Globbing
# ==============================================================================
# Treats #, ~, and ^ as patterns for filename globbing.
EXTENDED_GLOB=true

# ==============================================================================
# History
# ==============================================================================
# Does not display duplicates when searching the history.
HIST_FIND_NO_DUPS=true

# Does not enter immediate duplicates into the history.
HIST_IGNORE_DUPS=true

# Removes commands from history that begin with a space.
HIST_IGNORE_SPACE=true

# Does not execute command directly upon history expansion.
HIST_VERIFY=true

# Causes all terminals to share the same history session.
SHARE_HISTORY=true

# ==============================================================================
# Input/Output
# ==============================================================================
# Allows comments starting with # in interactive shell.
INTERACTIVE_COMMENTS=true

# Disallows `>` to overwrite files. Use `>|` or `>!` instead.
NO_CLOBBER=false

# ==============================================================================
# Job Control
# ==============================================================================
# Lists jobs in verbose format by default.
LONG_LIST_JOBS=true

# Prevents background jobs being given a lower priority.
NO_BG_NICE=true

# Prevents status report of jobs on shell exit.
NO_CHECK_JOBS=true

# Prevents SIGHUP to jobs on shell exit.
NO_HUP=true

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
# Python/UV: Environment Configuration
# ==============================================================================
# Set default virtual environment
# Prefer to default to a single shared virtual environment
export UV_PROJECT_ENVIRONMENT="$HOME/.venv"

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
