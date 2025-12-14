# shellcheck shell=zsh
# Environment - loaded for all types of shell sessions
# Source shared functions

# Debug
ZSH_DEBUG="${ZSH_DEBUG:-1}"
ZSH_TRACE="${ZSH_TRACE:-}"

# Setup log file
export ZLOG_FILE="$HOME/.zshlog"
: > "$HOME/.zshlog"

function zdebug() {
  if [[ -n $ZSH_DEBUG ]]; then
    echo "DEBUG: $*" >>"$ZLOG_FILE"
  fi
}

function ztrace() {
  if [[ -n $ZSH_TRACE ]]; then
    set -x
  fi
}

# Export a variable if this is WSL
function _is_wsl(){
  if grep -q Microsoft /proc/version; then
    zdebug ".zshenv: Session is in WSL"
    export IS_WSL=1
  fi
}
_is_wsl

# Check if mount point is mounted
function _is_mounted() {
  local mount_point="$1"
  # Strip trailing slash for consistency
  mount_point="${mount_point%/}"
  # Check if mount_point is present in the output of mount
  mount | grep -q " on $mount_point "
}

# ZSH Module configuration (built-in) {{{
# See: https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html
function _load_complist(){
  zdebug ".zshenv: Loading zsh/complist"
  zmodload zsh/complist
  autoload -U compinit
  compinit
  _comp_options+=(globdots)		# Include hidden files.
}
_load_complist

# ZSH Terminal Info module (dependency for zim) {{{
function _load_terminfo(){
  zdebug ".zshenv: Loading zsh/terminfo"
  zmodload -F zsh/terminfo +p:terminfo
}
_load_terminfo

# Keymaps
function _load_keybinds(){
  ## Use vim keys in tab complete menu:
  bindkey -M menuselect 'h' vi-backward-char
  bindkey -M menuselect 'j' vi-down-line-or-history
  bindkey -M menuselect 'k' vi-up-line-or-history
  bindkey -M menuselect 'l' vi-forward-char

  # Fix backspace bug when switching modes
  bindkey "^?" backward-delete-char

}
_load_keybinds

# Cursor customization
function _load_cursor(){
  echo -ne '\e[5 q' # Use beam shape cursor on startup.
  precmd() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.
}
_load_cursor

# Setup ripgrep
function _load_ripgrep(){
  if ! command -v rg &>/dev/null; then return; fi
  RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
if [[ ! -f "$RIPGREP_CONFIG_PATH" ]]; then
cat <<-EOF > "$RIPGREP_CONFIG_PATH"
--smart-case
--one-file-system
--heading
--no-line-number
--max-columns-preview
--trim
EOF
fi
zdebug ".zshenv: Configured Ripgrep"
}

function _load_aliases(){
  ZALIASES="$HOME/.aliases"
  if [[ -f "$ZALIASES" ]]; then
    source "$ZALIASES"
    zdebug ".zshenv: Sourcing $ZALIASES"
  else
    zdebug ".zshenv: Failed to source $ZALIASES"
  fi
}
_load_aliases

# Load zcolors, requires znap zcolors plugin
function _load_zcolors(){
  znap eval LS_COLORS 'dircolors -b LS_COLORS'
  zstyle \":completion:*:default\" list-colors \"${(s.:.)LS_COLORS}\"
  znap eval zcolors "zcolors ${(q)LS_COLORS}"
  zdebug ".zshenv: Setting up dircolors solarized"
}
if [ -x /usr/bin/dircolors ]; then
  test -r "$HOME/.dircolors" && eval "$(dircolors -b "$HOME/.dircolors")" || eval "$(dircolors -b)"
fi
if [[ ! -f "$HOME/.zsh-dircolors.config" ]]; then
  _load_zcolors
fi

# Function to load ssh-agent from yubikey
# Load ssh-key into agent
function ssh_load() {
  local agent_env="$HOME/.ssh/agent_env"
  # Reuse existing agent if possible
  if [[ -f "$agent_env" ]]; then
    source "$agent_env" 2>/dev/null || true
  fi
  # If existing agent socket works and has identities, skip starting a new one
  if [[ -S "$SSH_AUTH_SOCK" ]] && ssh-add -l >/dev/null 2>&1; then
    return
  fi
  # Start agent and add default identities only once
  eval "$(ssh-agent -s)" >/dev/null
  if [[ "${IS_WSL:-}" == "" ]]; then
    ssh-add -K || true
  else
    ssh-add || true
  fi
  umask 077
  printf 'export SSH_AUTH_SOCK=%q\nexport SSH_AGENT_PID=%q\n' "$SSH_AUTH_SOCK" "$SSH_AGENT_PID" >| "$agent_env"
}

# Function to append paths to $PATH from a file
function _append_to_path() {
  local dir
  dir="$1"
  realdir="$(readlink -f "$dir")"
  [[ -d "$realdir" ]] || return
  path=($path "$dir")
}

# Function to prepend paths to $PATH from a file
function _prepend_to_path() {
  local dir
  dir="$1"
  realdir="$(readlink -f "$dir")"
  [[ -d "$realdir" ]] || return
  path=("$dir" $path)
}

function _add_to_path() {
    paths_file="${1:-$HOME/.paths}"
    while IFS=',' read -r append prepend; do
        line="${append}${prepend}"
        [[ -z ${(S)line} ]] && continue
        [[ "$line" = \#* ]] && continue
        if [[ "${append:-}" != "" ]]; then
          zdebug ".zshenv: Appending $append to PATH"
          _append_to_path "$append"
        fi
        if [[ "${prepend:-}" != "" ]]; then
          zdebug ".zshenv: Prepending $prepend to PATH"
          _prepend_to_path "$prepend"
        fi
    done < "$paths_file" | sort -r
}

function _load_paths(){
  ZPATHS="$HOME/.paths"
  if [[ -f "$ZPATHS" ]]; then
    _add_to_path
    export PATH
    zdebug ".zshenv: Adding paths from $ZPATHS"
  else
    zdebug ".zshenv: Failed to add paths from $ZPATHS"
  fi
  zdebug ".zshenv: Deduping \$PATH"
  typeset -U PATH
}
_load_paths


# Load shared functions
function _load_zhared(){
  zhared="$HOME/.zshared"
  if [[ -f "$zhared" ]]; then
    source "$zhared"
    zdebug ".zshenv: Sourcing $zhared"
  else
    zdebug ".zshenv: Failed to source $zhared"
  fi
}
if [[ -z "$_zshared_loaded" ]]; then
  _load_zhared
fi
