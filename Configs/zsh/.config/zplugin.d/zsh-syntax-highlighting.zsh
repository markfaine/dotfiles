# shellcheck shell=zsh
# ==============================================================================
# zsh-users/zsh-syntax-highlighting configuration
# ==============================================================================
# Docs: https://github.com/zsh-users/zsh-syntax-highlighting

# Enable a conservative set of useful highlighters.
# - main: standard command line syntax highlighting
# - brackets: matching bracket highlighting
# - pattern: pattern token highlighting
# - regexp: regexp token highlighting
# - root: highlight dangerous root-owned commands when relevant
typeset -ga ZSH_HIGHLIGHT_HIGHLIGHTERS
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern regexp root)

# Pattern highlighter styles.
# Keep these modest and readable; adjust later to taste.
typeset -gA ZSH_HIGHLIGHT_PATTERNS
# Use a deeper red index to avoid washed-out pink reds on some terminal themes.
ZSH_HIGHLIGHT_PATTERNS+=('rm -rf *' 'fg=160,bold')
ZSH_HIGHLIGHT_PATTERNS+=('sudo *' 'fg=yellow')

# Style overrides for built-in highlight groups.
typeset -gA ZSH_HIGHLIGHT_STYLES

# Override default comment color.
# Default "ansigray" is too faint on dark backgrounds.
ZSH_HIGHLIGHT_STYLES[comment]='fg=7'

# Slightly emphasize aliases and reserved words for readability.
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=yellow,bold'

# Keep unknown tokens obvious without being harsh.
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=160,bold'

# Bracket highlight styles.
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=yellow,bold'

if typeset -f zdebug >/dev/null 2>&1; then
  zdebug ".zplugin.d/zsh-syntax-highlighting.zsh: Applied zsh-syntax-highlighting settings"
fi
