zimfw() { source $HOME/.zim/zimfw.zsh "${@}" }
zmodule() { source $HOME/.zim/zimfw.zsh "${@}" }
fpath=($HOME/.zim/modules/utility/functions $HOME/.zim/modules/duration-info/functions $HOME/.zim/modules/git-info/functions $HOME/.zim/modules/zsh-completions/src $HOME/.zim/modules/prompt-pwd/functions $HOME/.zim/modules/archive/functions $HOME/.zim/modules/asdf/functions $HOME/.zim/modules/zim-yq/functions ${fpath})
autoload -Uz -- mkcd mkpw duration-info-precmd duration-info-preexec coalesce git-action git-info prompt-pwd archive lsarchive unarchive asdf
source $HOME/.zim/modules/environment/init.zsh
source $HOME/.zim/modules/input/init.zsh
source $HOME/.zim/modules/termtitle/init.zsh
source $HOME/.zim/modules/utility/init.zsh
source $HOME/.zim/modules/duration-info/init.zsh
source $HOME/.zim/modules/bira/bira.zsh-theme
source $HOME/.zim/modules/completion/init.zsh
source $HOME/.zim/modules/gitster/gitster.zsh-theme
source $HOME/.zim/modules/ssh/init.zsh
source $HOME/.zim/modules/fzf/init.zsh
source $HOME/.zim/modules/archive/init.zsh
source $HOME/.zim/modules/asdf/init.zsh
source $HOME/.zim/modules/zim-yq/init.zsh
source $HOME/.zim/modules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/.zim/modules/zsh-history-substring-search/zsh-history-substring-search.zsh
source $HOME/.zim/modules/zsh-autosuggestions/zsh-autosuggestions.zsh
