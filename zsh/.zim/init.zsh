zimfw() { source "$HOME/.zim/zimfw.zsh" "${@}" }
zmodule() { source "$HOME/.zim/zimfw.zsh" "${@}" }
fpath=("$HOME/.zim/modules/git/functions" "$HOME/.zim/modules/zsh-completions/src" "$HOME/.zim/modules/zsh-completions/src" "$HOME/.zim/modules/zsh-completions/src" ${fpath})
autoload -Uz -- git-alias-lookup git-branch-current git-branch-delete-interactive git-branch-remote-tracking git-dir git-ignore-add git-root git-stash-clear-interactive git-stash-recover git-submodule-move git-submodule-remove
source "$HOME/.zim/modules/git/init.zsh"
