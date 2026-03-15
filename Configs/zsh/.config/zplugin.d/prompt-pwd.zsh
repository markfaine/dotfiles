# shellcheck shell=zsh
# ==============================================================================
# zimfw/prompt-pwd configuration
# ==============================================================================
# Docs: https://github.com/zimfw/prompt-pwd

# Truncate path to git root when inside a git repository.
zstyle ':zim:prompt-pwd' git-root yes

# Show at most this many trailing path components (positive integer).
# Increase for more context, decrease for shorter prompts.
zstyle ':zim:prompt-pwd:tail' length 3

# Fish-style shortening per path component.
# 0 disables shortening entirely (default plugin behavior).
zstyle ':zim:prompt-pwd:fish-style' dir-length 1

# Format for a git root directory path component.
# %d is replaced with the git root directory name.
zstyle ':zim:prompt-pwd:git-root' format '%d'

# Path separator format.
# Supports prompt expansion escapes if desired.
zstyle ':zim:prompt-pwd:separator' format '❯'
