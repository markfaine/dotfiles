# shellcheck shell=zsh
# ==============================================================================
# zsh-users/zsh-history-substring-search configuration
# ==============================================================================
# Docs: https://github.com/zsh-users/zsh-history-substring-search

# Highlight style for query text found in matching history entries.
# Default upstream style is bold, white on magenta.
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=magenta,fg=white,bold'

# Highlight style when no history entry matches query.
# Default upstream style is bold, white on red.
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'

# Globbing flags used to search history.
# "i" means case-insensitive matching.
HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'

# Fuzzy matching by words in order (disabled by default).
HISTORY_SUBSTRING_SEARCH_FUZZY=''

# Match only from the start of each history entry (disabled by default).
HISTORY_SUBSTRING_SEARCH_PREFIXED=''

# Ensure globally unique search results.
# Off by default; set to non-empty to enable.
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=''

# Timeout (seconds) for clearing search highlight.
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_TIMEOUT=1

# ------------------------------------------------------------------------------
# Key bindings
# ------------------------------------------------------------------------------
# Prefer terminfo-capable arrow key bindings where available.
if [[ -n "${terminfo[kcuu1]:-}" ]]; then
	bindkey "$terminfo[kcuu1]" history-substring-search-up
fi
if [[ -n "${terminfo[kcud1]:-}" ]]; then
	bindkey "$terminfo[kcud1]" history-substring-search-down
fi

# Fallback ANSI arrow key bindings.
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Also support emacs-style ctrl-p/ctrl-n navigation.
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

# Also support vi command mode k/j navigation.
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
