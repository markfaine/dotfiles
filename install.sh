#!/bin/bash
# Run with bash ./install.sh
set +euo pipefail
export DEBIAN_FRONTEND=noninteractive

tstamp="$(date +%Y%m%d_%H%M%S)"
DIRS=( "$HOME/.tmux" "$HOME/.vim" "$HOME/.config/nvim" "$HOME/.zim" "$HOME/.bash_it" )

printf "Backing up files and removing existing symlinks\n"
mapfile -t files < <(find ~/dotfiles/dotfiles -type f)
for file in "${files[@]}"; do
    stem="${file##*dotfiles/}"
    if [[ -e "$HOME/$stem" ]]; then
        if [[ -h "$HOME/$stem" ]]; then
            rm -f "$HOME/$stem"
        elif [[ -f "$HOME/$stem" ]]; then
	    bn="$(basename "$HOME/$stem")"
            mv "$HOME/$stem" "$HOME/$bn-$tstamp"
	fi
    fi
done

# Directories
printf "Backing up dirs and removing existing symlinks\n"
for thedir in "${DIRS[@]}"; do
    if [[ -e "$thedir" ]]; then
        if [[ -h "$thedir" ]]; then
            rm -f "$thedir"
        elif [[ -d "$thedir" ]]; then
            mv "$thedir" "$thedir-tstamp"	
	fi
    fi
done

printf "Stow activate packages from ~/dotfiles\n"
pushd ~/dotfiles &>/dev/null
mapfile -t packages < <(find . -mindepth 1 -maxdepth 1 -type d)
for package in "${packages[@]}"; do
    stow "$package"
done

# Install apt-get packages 
printf "Install apt packages\n"
sudo apt-get update &>/dev/null
sudo apt-get install -y zsh tmux ripgrep git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev &>/dev/null

# Install ZSH, change the shell to zsh, and install zim
printf "Set default shell to zsh\n"
if [[ ! "$SHELL" =~ "zsh" ]]; then
    sudo chsh -s "$(command -v zsh)" "$LOGNAME" 
fi
printf "Install zim\n"
if [[ ! -e "~/.zim" ]]; then
    curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
fi

# If neovim is installed remove it and install it from pre-built archive
printf "Install neovim\n"
sudo apt-get remove nvim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz
printf '%s' "PATH=\"\$PATH:/opt/nvim-linux64/bin\"\n" >> ~/.zshenv
printf '%s' "PATH=\"\$PATH:/opt/nvim-linux64/bin\"\n" >> ~/.bashrc

# Install fzf
printf "Install fzf\n"
FZFDIR="$HOME/.fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git "$FZFDIR" &>/dev/null
if [[ ! -x "$FZFDIR/install" ]]; then
    printf "The file at %s does not exist or is inaccessible\n" "$FZFDIR/install"
    exit 1
fi
"$FZFDIR/install"
if [[ -d "$FZFDIR" ]]; then
    rm -rf "${FZFDIR:?}"
fi

# Install node/nvm
printf "Install Node/NPM and node packages\n"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install 21
node -v
npm -v
# Install node packages
npm install tree-sitter

# Install asdf/ruby/tmuxinator
printf "Install ASDF, Ruby and Ruby packages\n"
git clone https://github.com/excid3/asdf.git ~/.asdf
printf "%s\n" "legacy_version_file = yes" >> ~/.asdfrc
# bash
printf ". %s\n" "\$HOME/.asdf/asdf.sh" >> ~/.bashrc
printf ". %s\n" "\$HOME/.asdf/completions/asdf.bash" >> ~/.bashrc
# zsh
printf ". %s\n" "\$HOME/.asdf/asdf.sh" >> ~/.zshenv
printf ". %s\n" "\$HOME/.asdf/completions/asdf.bash" >> ~/.zshenv
# Source bashrc
. ~/.bashrc
asdf plugin add ruby
asdf install ruby 3.3.0
asdf global ruby 3.3.0
gem install tmuxinator
gem update --system
ruby -v

# Install Github CLI
printf "Install Github CLI\n"
sudo mkdir -p -m 755 /etc/apt/keyrings && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y
