# This is the configuration file for the zimfw/git-info plugin
# See: https://github.com/zimfw/git-info

# Configure git-info plugin {{{
# See: https://github.com/zimfw/git-info
setopt nopromptbang prompt{cr,percent,sp,subst}
zstyle ':zim:git-info:branch' format 'branch:%b'
zstyle ':zim:git-info:commit' format 'commit:%c'
zstyle ':zim:git-info:remote' format 'remote:%R'
zstyle ':zim:git-info:keys' format \
    'prompt'  'git(%b%c)' \
    'rprompt' '[%R]'
autoload -Uz add-zsh-hook && add-zsh-hook precmd git-info
PS1='${(e)git_info[prompt]}%# '
RPS1='${(e)git_info[rprompt]}'
# End Configure git-info plugin }}}
