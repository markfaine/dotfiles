# ==============================================================================
# Environment Settings
# ==============================================================================

# Performs cd to a directory if the typed command is invalid, but is a directory.
setopt AUTO_CD

# Makes cd push the old directory to the directory stack.
setopt AUTO_PUSHD

# Does not print the working directory after a cd.
setopt CD_SILENT

# Does not push multiple copies of the same directory to the stack.
setopt PUSHD_IGNORE_DUPS

# Does not print the directory stack after pushd or popd.
setopt PUSHD_SILENT

# Has pushd without arguments act like `pushd ${HOME}`.
setopt PUSHD_TO_HOME

# ==============================================================================
# Expansion and Globbing
# ==============================================================================
# Treats #, ~, and ^ as patterns for filename globbing.
setopt EXTENDED_GLOB

# ==============================================================================
# History
# ==============================================================================
# The name and location of the history file
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/.zsh_history"

# The number of lines that are kept in memory for the current, active shell session.
HISTSIZE="5000"

# The number of lines that are written to the history file on disk.
SAVEHIST="5000"

# Commands to ignore when recording history (wildcard patterns)
HISTORY_IGNORE="(ls*|ll*|pwd|exit|cd*)"

# Does not display duplicates when searching the history.
setopt HIST_FIND_NO_DUPS

# Does not execute command directly upon history expansion.
setopt HIST_VERIFY

# Allow history entries to overwrite existing files
setopt HIST_ALLOW_CLOBBER

# Causes all terminals to share the same history session.
setopt SHARE_HISTORY

# Append history incrementally to HISTFILE
setopt INC_APPEND_HISTORY

# Enable ! history expansion
setopt BANG_HIST

# Skip duplicate commands when expanding history
setopt HIST_IGNORE_ALL_DUPS

# Don't save commands that start with a space
setopt HIST_IGNORE_SPACE

# Don't store function definitions in history
setopt HIST_NO_FUNCTIONS

# ==============================================================================
# Input/Output
# ==============================================================================
# Allows comments starting with # in interactive shell.
setopt INTERACTIVE_COMMENTS

# Allows `>` to overwrite files.
setopt CLOBBER

# ==============================================================================
# Job Control
# ==============================================================================
# Lists jobs in verbose format by default.
setopt LONG_LIST_JOBS

# Prevents background jobs being given a lower priority.
setopt NO_BG_NICE

# Prevents status report of jobs on shell exit.
setopt NO_CHECK_JOBS

# Prevents SIGHUP to jobs on shell exit.
setopt NO_HUP

# ==============================================================================
# Exports
# ==============================================================================

# ==============================================================================
# Python/UV: Environment Configuration
# ==============================================================================
# Set default virtual environment
# Prefer to default to a single shared virtual environment
export UV_PROJECT_ENVIRONMENT="${ZDOTDIR:-$HOME}/.venv"

# ==============================================================================
# Editor & Pager Configuration
# ==============================================================================
# Primary editor for environment
export EDITOR="nvim"

# # Pager for various commands (bat provides syntax highlighting)
# if (( $+commands[bat] )); then
#   export PAGER="bat"
# else
#   export PAGER="less"
# fi

# # Pager for git commands (use default PAGER)
# export GIT_PAGER="$PAGER"

# # Pager for man pages (use default PAGER)
# export MANPAGER="$PAGER"

# # Pager for systemd commands
# export SYSTEMD_PAGER="$PAGER"

# ==============================================================================
# Input
# ==============================================================================
# SSH authentication prompt program (for passphrase input)
# Only set if ssh-askpass is available
if (( $+commands[ssh-askpass] )); then
  export SSH_ASKPASS="$(command -v ssh-askpass)"
fi

# ==============================================================================
# Terminal & Display
# ==============================================================================
# Disable automatic terminal title updates by shell
export DISABLE_AUTO_TITLE=0

# Enable colored output for systemd commands
export SYSTEMD_COLORS=0

# Flag for systemd pager (secure mode)
export SYSTEMD_PAGERSECURE=0

# ==============================================================================
# CLI Tools - Integration and Completion
# ==============================================================================
# Use 'fd'
if (( $+commands[fzf] && $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --exclude .git'
fi

# UI and Previews
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info \
  --bind 'ctrl-/:toggle-preview' --color='header:italic'"

# File Previews (CTRL-T)
if (( $+commands[bat] )); then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :500 {}'"
fi

# Directory Previews (ALT-C)
if (( $+commands[eza] )); then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {} | head -200'"
elif (( $+commands[tree] )); then
    export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
fi

# ==============================================================================
# System Configuration
# ==============================================================================
# Timezone for time-related functions
if [[ "${TZ:-}" == "" ]]; then
  export TZ="America/Chicago"
fi
