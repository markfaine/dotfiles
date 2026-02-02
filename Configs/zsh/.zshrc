# shellcheck shell=zsh
# User configuration sourced by interactive shells
# ## See https://zsh.sourceforge.io/Doc/Release/Options.html

# Load znap
function _load_znaprc(){
  zdebug ".zshrc: _load_znaprc called, _znaprc_loaded=$_znaprc_loaded"
  if [[ -n  $_znaprc_loaded ]]; then 
    zdebug ".zshrc: Skipping znaprc - already loaded"
    return
  fi
  ZNAPRC="$HOME/.znaprc"
  zdebug ".zshrc: Checking for $ZNAPRC"
  if [[ -f "$ZNAPRC" ]]; then
    zdebug ".zshrc: Sourcing $ZNAPRC"
    # shellcheck source=/dev/null
    source "$ZNAPRC"
    _znaprc_loaded=1
    zdebug ".zshrc: Sourced $ZNAPRC successfully"
  else
    zdebug ".zshrc: Failed to source $ZNAPRC - file not found"
  fi
}
_load_znaprc

# Setup prompt
znap prompt sindresorhus/pure

# Export path to child processes
#zdebug ".zshrc: Exporting PATH: $PATH"
#export PATH
