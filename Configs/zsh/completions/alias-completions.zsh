# Completion mappings for shell aliases
# Maps aliases to their corresponding completion functions
# This file must be sourced AFTER compinit is loaded

# ==============================================================================
# VCS (Version Control) Completions
# ==============================================================================
# git alias gets completions from _git
compdef _git git

# ==============================================================================
# Multiplexer Completions
# ==============================================================================
# tmux alias gets completions from _tmux
compdef _tmux tmux

# ==============================================================================
# Editor Completions
# ==============================================================================
# vim/vi aliases get completions from _vim
compdef _vim vim
compdef _vim vi

# VS Code aliases get completions from code
[[ -n "${+commands[code-insiders]}" ]] && compdef _code code-insiders
[[ -n "${+commands[code-insiders]}" ]] && compdef _code-insiders ci

# ==============================================================================
# File Management Completions
# ==============================================================================
# ls aliases get completions from _ls
if command -v eza &>/dev/null; then
    # If using eza, use eza's completion
    compdef _eza ls
else
    # Otherwise use ls's completion
    compdef _ls ls
fi
compdef _ls ll
compdef _ls kk

# ==============================================================================
# Disk Management Completions
# ==============================================================================
# df alias (aliased to duf)
if command -v duf &>/dev/null; then
    compdef _duf df
fi

# ==============================================================================
# Pager/Help Completions
# ==============================================================================
# man function (falls back to tldr) gets man completions
compdef _man man

# ==============================================================================
# Utility Completions
# ==============================================================================
# tmuxinator if available
if command -v tmuxinator &>/dev/null; then
    compdef _tmuxinator tmuxinator
fi
