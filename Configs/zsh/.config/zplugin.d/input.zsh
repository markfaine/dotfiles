# shellcheck shell=zsh
# ==============================================================================
# zimfw/input configuration
# ==============================================================================
# Docs: https://github.com/zimfw/input

# Double-dot parent directory expansion, which will turn a . typed after .. into /..
# (e.g. .... into ../../..) so you don't need to type too many slashes and dots.
# Conversely, it will contract the last expansion when BACKSPACE is typed
# (e.g. ../../..BACKSPACE into ../..).
zstyle ':zim:input' double-dot-expand yes
