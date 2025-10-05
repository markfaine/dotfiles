# This plugin handles the configuration for zsh-abbr, a plugin that 
# allows for command line abbreviations that work like macros
# See: https://github.com/olets/zsh-abbr
# For documentation on abbreviations, 
# see here: https://zsh-abbr.olets.dev/abbreviation-expansion.html
zdebug "loaded configuration for zsh-abbr"

# Save abbreviations to history {{{
ABBR_EXPAND_PUSH_ABBREVIATION_TO_HISTORY=1
# End Save abbreviations to history }}}

# Save lines with abbreviations to history {{{
ABBR_EXPAND_AND_ACCEPT_PUSH_ABBREVIATED_LINE_TO_HISTORY=1
# End Save lines with abbreviations to history }}}

# Remind about abbreviations {{{
ABBR_GET_AVAILABLE_ABBREVIATION=1
ABBR_LOG_AVAILABLE_ABBREVIATION=1
ABBR_LOG_AVAILABLE_ABBREVIATION_AFTER=1
ABBR_UNUSED_ABBREVIATION=1
# End Remind about abbreviations }}}

