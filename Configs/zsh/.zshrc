# shellcheck shell=zsh
# User configuration sourced by interactive shells
# https://zsh.sourceforge.io/Doc/Release/Options.html
#
# Initialization Order:
#   1. .zshenv - Loaded by all shells (environment)
#   2. .zprofile - Loaded by login shells (login setup)
#   3. .zshrc - Loaded by interactive shells
#   4. .zlogin - Loaded by login shells (after .zshrc)
#
# This file:
#   - Loads the znap plugin manager and plugins
#   - Configures the prompt
#   - Sets up tool environments

# ==============================================================================
# Shell Configuration Loading
# ==============================================================================
# Set the configuration directory if not already set
ZCONFIG="${ZCONFIG:-$HOME/.config/dotfiles/Configs/zsh}"

# Load shared functions
if [[ -f "$ZCONFIG/.zshared" ]]; then
  zdebug ".zshrc: Loading shared shell functions"
  # shellcheck source=/dev/null
  . "$ZCONFIG/.zshared"
else
  zdebug ".zshrc: Shared functions not found (optional)"
fi

# Load shell aliases
if [[ -f "$ZCONFIG/.aliases" ]]; then
  zdebug ".zshrc: Loading shell aliases"
  # shellcheck source=/dev/null
  . "$ZCONFIG/.aliases"
else
  zdebug ".zshrc: Aliases file not found (optional)"
fi

# ==============================================================================
# Plugin Manager: Znap Loading
# ==============================================================================
# Load znap plugin manager and configuration
ZNAPRC="$HOME/.znaprc"
zdebug ".zshrc: Loading znap plugin manager from $ZNAPRC"

if [[ -f "$ZNAPRC" ]]; then
  # shellcheck source=/dev/null
  if source "$ZNAPRC"; then
    zdebug ".zshrc: Znap loaded successfully"
  else
    zdebug ".zshrc: ERROR - Failed to source $ZNAPRC"
    echo "Warning: Failed to load znap plugin manager" >&2
  fi
else
  zdebug ".zshrc: ERROR - $ZNAPRC not found"
  echo "Warning: Znap configuration not found at $ZNAPRC" >&2
fi

# ==============================================================================
# Prompt Configuration
# ==============================================================================
# Configure pure prompt theme from sindresorhus
# Fallback to simple prompt if plugin manager failed
# Note: Pure can have terminal formatting issues with commented text
# PROMPT_EOL_MARK helps prevent line wrapping display issues
if (( ${+commands[znap]} )) || typeset -f znap > /dev/null 2>&1; then
  zdebug ".zshrc: Setting up pure prompt via znap"

  # Prevent invisible characters in line wrapping with comments
  # This should be set before loading the theme
  PROMPT_EOL_MARK=""

  # Pure prompt configuration for better visibility
  # Use git untracked dirty indicator
  PURE_GIT_UNTRACKED_DIRTY=1
  # Force minimal processing to reduce rendering issues
  PURE_PROMPT_TCSETPGRP=1

  znap prompt sindresorhus/pure || {
    zdebug ".zshrc: Failed to load pure prompt, using simple prompt"
    PS1='%~ %# '
  }
else
  zdebug ".zshrc: Znap not available, using simple prompt"
  PS1='%~ %# '
fi

# ==============================================================================
# Python UV Environment
# ==============================================================================
# Load UV (fast Python package installer/environment manager) if available
# UV provides fast Python package management and environment handling
UV_ENV="$HOME/.local/opt/uv/env"
if [[ -f "$UV_ENV" ]]; then
  zdebug ".zshrc: Loading UV environment from $UV_ENV"
  # shellcheck source=/dev/null
  . "$UV_ENV"
else
  zdebug ".zshrc: UV environment file not found at $UV_ENV (optional)"
fi

# ==============================================================================
# Alias Completion Configuration
# ==============================================================================
# Load completion function mappings for shell aliases
# This must run after compinit (loaded in .zshenv) to properly register completions
if [[ -f "$ZCONFIG/completions/alias-completions.zsh" ]]; then
  zdebug ".zshrc: Loading alias completion mappings"
  # shellcheck source=/dev/null
  . "$ZCONFIG/completions/alias-completions.zsh"
else
  zdebug ".zshrc: Alias completions file not found (optional)"
fi

# ==============================================================================
# Syntax Highlighting Customization
# ==============================================================================
# Override zsh-syntax-highlighting plugin's default comment color
# Default "ansigray" is too faint on dark backgrounds
# Use bright gray for better contrast and visibility
if [[ -n "${ZSH_HIGHLIGHT_STYLES+x}" ]]; then
  ZSH_HIGHLIGHT_STYLES[comment]='fg=7'  # Bright white-ish gray instead of ansigray
  zdebug ".zshrc: Set ZSH_HIGHLIGHT_STYLES[comment] to bright gray"
fi

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
