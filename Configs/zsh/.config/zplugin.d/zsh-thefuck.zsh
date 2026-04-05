# A little less noticable when in a work environment
zstyle ":prezto:module:thefuck" alias "tf"

# Disable the default keybinding
zstyle ":prezto:module:thefuck" bindkey "no"

# Customized keybinding
# bindkey "\e\e" fuck-command-line

# If .zshrc changes regenerate cache
zstyle ":prezto:runcom" zpreztorc "${ZDOTDIR:-$HOME}/.zshrc"
