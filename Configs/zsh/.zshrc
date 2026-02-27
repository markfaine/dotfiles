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
# Plugin Manager: Znap Loading
# ==============================================================================
# Guard against multiple sourcing of .zshrc
# (useful if user manually sources this file multiple times)
if [[ -z "$_zshrc_loaded" ]]; then
  export _zshrc_loaded=1

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
else
  zdebug ".zshrc: Skipping plugin loading - .zshrc already loaded"
fi

# ==============================================================================
# Prompt Configuration
# ==============================================================================
# Configure pure prompt theme from sindresorhus
# Fallback to simple prompt if plugin manager failed
if (( ${+commands[znap]} )) || typeset -f znap > /dev/null 2>&1; then
  zdebug ".zshrc: Setting up pure prompt via znap"
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
# User Extension Hooks
# ==============================================================================
# Allow users to add custom initialization without modifying this file
# Create ~/.zshrc.local for local customizations that won't be version controlled
if [[ -f "$HOME/.zshrc.local" ]]; then
  zdebug ".zshrc: Loading local overrides from ~/.zshrc.local"
  # shellcheck source=/dev/null
  . "$HOME/.zshrc.local"
fi
