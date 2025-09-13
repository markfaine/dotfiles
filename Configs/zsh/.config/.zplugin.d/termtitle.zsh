# This is the configuration for the zimfw/termtitle plugin
# See: https://github.com/zimfw/termtitle

# Configure terminal title module {{{
zstyle ':zim:termtitle' hooks 'preexec' 'precmd'
zstyle ':zim:termtitle:preexec' format '${${(A)=1}[1]}'
zstyle ':zim:termtitle:precmd'  format '%1~'
# End Configure terminal title mddule }}}
