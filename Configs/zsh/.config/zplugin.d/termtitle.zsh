# shellcheck shell=zsh
# ==============================================================================
# zimfw/termtitle configuration
# ==============================================================================
# Docs: https://github.com/zimfw/termtitle

# Default title format shown before each prompt.
# %n = user, %m = host, %~ = current working directory
zstyle ':zim:termtitle' format '%n@%m: %~'

# Update title when command starts and before prompt returns.
# This gives command context while running and cwd context at prompt.
zstyle ':zim:termtitle' hooks 'preexec' 'precmd'

# While a command is running, show only the command name in terminal title.
zstyle ':zim:termtitle:preexec' format '${${(Az)1}[1]}'

# Before each prompt, show compact current directory name.
zstyle ':zim:termtitle:precmd' format '%1~'

