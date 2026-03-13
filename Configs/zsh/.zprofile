# shellcheck shell=zsh
# ==============================================================================
# Profile Shell Initialization
# ==============================================================================
# Sourced once at login before .zlogin
# Purpose: Environment variables and startup programs for login shells
#
# Login shell initialization order:
#   1. .zshenv    - Always sourced (environment variables, functions)
#   2. .zprofile  - Login shells only (startup programs, PATH manipulation)
#   3. .zshrc     - Interactive shells only (interactive config, prompts)
#   4. .zlogin    - Login shells only (final setup, mail checks, motd)
#
# Note: Most environment setup is in .zshenv for consistency across all shells.
# Use .zprofile only if you need login-shell-specific program startup.

# ==============================================================================
# Login-Specific Setup
# ==============================================================================
# Add login-specific programs or environment setup here if needed
# Examples:
#   - Start SSH agent (for login sessions)
#   - Initialize environment managers (mise, pyenv - already in .zshenv)
#   - Load display-specific settings (DISPLAY for X11)
