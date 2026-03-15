# ==============================================================================
# Prompt Configuration
# ==============================================================================
# Configure pure prompt theme from sindresorhus
# Note: Pure can have terminal formatting issues with commented text
# PROMPT_EOL_MARK helps prevent line wrapping display issues

# Prevent invisible characters in line wrapping with comments
# This should be set before loading the theme
PROMPT_EOL_MARK=""

# Pure prompt configuration for better visibility
# Use git untracked dirty indicator
PURE_GIT_UNTRACKED_DIRTY=1

# Force minimal processing to reduce rendering issues
PURE_PROMPT_TCSETPGRP=1
