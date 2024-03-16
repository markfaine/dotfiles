# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zprofile.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zprofile.pre.zsh"
# ## Ansible managed

# ## Source .zshrc
if [[ -f "$HOME/.zshrc" ]]; then
    . "$HOME/.zshrc"
fi

# ## Start SSH server if required
if [[ -x "$HOME/bin/start-ssh.sh" ]]; then
    sudo "$HOME//bin/start-ssh.sh"
fi

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zprofile.post.zsh" ]] && builtin source "$HOME/.fig/shell/zprofile.post.zsh"
