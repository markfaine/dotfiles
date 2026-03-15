# shellcheck shell=zsh
# ==============================================================================
# fzf-tab configuration
# ==============================================================================
# Docs: https://github.com/Aloxaf/fzf-tab

# Show flag descriptions in a preview window
zstyle ':fzf-tab:complete:*:*' fzf-preview '[[ $group == "[option]" ]] && echo $desc'
