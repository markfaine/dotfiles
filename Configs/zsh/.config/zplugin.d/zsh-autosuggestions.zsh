# shellcheck shell=zsh
# ==============================================================================
# zsh-users/zsh-autosuggestions configuration
# ==============================================================================
# Docs: https://github.com/zsh-users/zsh-autosuggestions

# Suggestion highlight style.
# Default from plugin is fg=8
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=7'

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
