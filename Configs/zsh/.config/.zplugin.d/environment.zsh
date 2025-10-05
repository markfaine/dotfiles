# This file contains settings relevant to the zimfw/environment zsh plugin

# Set the path to the history file {{{
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
export HISTFILE
# End Set the path to the history file }}}

# AUTO_CD performs cd to a directory if the typed command is invalid, but is a directory.
AUTO_CD=true

# AUTO_PUSHD makes cd push the old directory to the directory stack.
AUTO_PUSHD=true

# CD_SILENT does not print the working directory after a cd.
CD_SILENT=true

# PUSHD_IGNORE_DUPS does not push multiple copies of the same directory to the stack.
PUSHD_IGNORE_DUPS=true

# PUSHD_SILENT does not print the directory stack after pushd or popd.
PUSHD_SILENT=true

# PUSHD_TO_HOME has pushd without arguments act like pushd ${HOME}.
PUSHD_TO_HOME=true

# EXTENDED_GLOB treats #, ~, and ^ as patterns for filename globbing.
EXTENDED_GLOB=false

# HIST_FIND_NO_DUPS does not display duplicates when searching the history.
HIST_FIND_NO_DUPS=true

# HIST_IGNORE_DUPS does not enter immediate duplicates into the history.
HIST_IGNORE_DUPS=true

# HIST_IGNORE_SPACE removes commands from the history that begin with a space.
HIST_IGNORE_SPACE=true

# HIST_VERIFY doesn't execute the command directly upon history expansion.
HIST_VERIFY=true

# SHARE_HISTORY causes all terminals to share the same history 'session'.
SHARE_HISTORY=true

# INTERACTIVE_COMMENTS allows comments starting with # in the shell.
INTERACTIVE_COMMENTS=true

# NO_CLOBBER disallows > to overwrite existing files. Use >| or >! instead.
NO_CLOBBER=false

# LONG_LIST_JOBS lists jobs in verbose format by default.
LONG_LIST_JOBS=true

# NO_BG_NICE prevents background jobs being given a lower priority.
NO_BG_NICE=false

# NO_CHECK_JOBS prevents status report of jobs on shell exit.
NO_CHECK_JOBS=false

# NO_HUP prevents SIGHUP to jobs on shell exit.
NO_HUP=false

# Not strictly related to this plugin but adjacent {{{

# AUTO_PARAM_SLASH It's annoying to always have to type a slash before tabbing
setopt AUTO_PARAM_SLASH

# Remove path separator from WORDCHARS
# This makes it so that / doen't count as part of a word in line editors
# For example, CTRL-W or ALT-Backspace
WORDCHARS=${WORDCHARS//[\/]/}
# End Not strictly related to this plugin but adjacent }}}
