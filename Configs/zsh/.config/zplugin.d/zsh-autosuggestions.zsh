# shellcheck shell=zsh
# ==============================================================================
# zsh-users/zsh-autosuggestions configuration
# ==============================================================================
# Docs: https://github.com/zsh-users/zsh-autosuggestions

# Suggestion highlight style.
# Default from plugin is fg=8; keep it explicit for clarity.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Suggestion strategy order (first match wins).
# - history: fast and predictable
# - completion: fallback when history has no good suggestion
typeset -ga ZSH_AUTOSUGGEST_STRATEGY
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Disable suggestions for very large buffers (helps when pasting long text).
# Recommended by plugin docs: 20
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Ignore history suggestions that match these patterns.
# Customize as needed (e.g., 'cd *').
ZSH_AUTOSUGGEST_HISTORY_IGNORE=''

# Ignore completion suggestions for matching buffers.
# Keep empty by default; customize as needed (e.g., 'git *').
ZSH_AUTOSUGGEST_COMPLETION_IGNORE=''

# Widget mapping arrays (documented extension points).
# Keep defaults from plugin by leaving arrays empty here.
typeset -ga ZSH_AUTOSUGGEST_CLEAR_WIDGETS
typeset -ga ZSH_AUTOSUGGEST_ACCEPT_WIDGETS
typeset -ga ZSH_AUTOSUGGEST_EXECUTE_WIDGETS
typeset -ga ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS
typeset -ga ZSH_AUTOSUGGEST_IGNORE_WIDGETS

# Notes on optional advanced toggles from docs:
# - Async mode is enabled by default on zsh >= 5.0.8.
# - Set ZSH_AUTOSUGGEST_MANUAL_REBIND to disable automatic rebinds.
#   Leave unset for sane default behavior.
