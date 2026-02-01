# shellcheck shell=zsh
# User configuration sourced by interactive shells
# ## See https://zsh.sourceforge.io/Doc/Release/Options.html

# Load znap
function _load_znaprc(){
  if [[ -n  $_znaprc_loaded ]]; then return; fi
  ZNAPRC="$HOME/.znaprc"
  if [[ -f "$ZNAPRC" ]]; then
    # shellcheck source=/dev/null
    source "$ZNAPRC"
    zdebug ".zshrc: Sourcing $ZNAPRC"
    export _znaprc_loaded=1
  else
    zdebug ".zshrc: Failed to source $ZNAPRC"
  fi
}
_load_znaprc

# Setup prompt
znap prompt sindresorhus/pure

# Export path to child processes
#zdebug ".zshrc: Exporting PATH: $PATH"
#export PATH
