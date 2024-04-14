#!/bin/bash
# Run with bash ./install.sh
set +euo pipefail

# Version of NVM to install
NVM_VERSION=0.39.7
NODE_VERSION=21
RUBY_VERSION=3.3.0

tstamp="$(date +%Y%m%d_%H%M%S)"
process="$(readlink "/proc/$$/exe")"
if [[ ! "$process" =~ "bash" ]]; then
    printf "This script is intended to be run only with bash\n"
    printf "Usage: bash $0"
    exit 1
fi

DIRS=( "$HOME/.tmux" "$HOME/.vim" "$HOME/.config/nvim" "$HOME/.zim" "$HOME/.bash_it" )
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Install apt-get packages 
export DEBIAN_FRONTEND=noninteractive
printf "\nInstall apt packages\n"
sudo apt-get update &>/dev/null
sudo apt-get install -y git curl wget stow zsh direnv jq tmux ripgrep git zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev &>/dev/null

# Change the shell to zsh, and install zim
if [[ ! "$SHELL" =~ "zsh" ]]; then
    printf "The default shell is currently set to $SHELL, you may wish to change it." 
fi

printf "\nInstall zim\n"
rm -rf "$HOME/.zim"
rm -f "$HOME/.zshrc" 
rm -f "$HOME/.zshenv" 
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh #&>/dev/null

# If neovim is installed remove it and install it from pre-built archive
printf "\nInstall/Upgrade neovim\n"
sudo apt-get remove nvim &>/dev/null
curl -s -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz -o /tmp/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf "/tmp/nvim-linux64.tar.gz" &>/dev/null
if [[ -x /opt/nvim-linux64/bin/nvim ]];  then
    version="$(/opt/nvim-linux64/bin/nvim --version | head -1)"
    printf "$version\n"
fi

# Install fzf
printf "\nInstall/Upgrade fzf\n"
FZFDIR="$HOME/.fzf"
rm -rf "${FZFDIR:?}"
git clone --depth 1 https://github.com/junegunn/fzf.git "$FZFDIR" &>/dev/null
if [[ ! -x "$FZFDIR/install" ]]; then
    printf "The file at %s does not exist or is inaccessible\n" "$FZFDIR/install"
    exit 1
fi
"$FZFDIR/install" --all &>/dev/null
if [[ -x "$HOME/.fzf/bin/fzf" ]]; then
    printf "fzf version: %s\n" "$("$HOME/.fzf/bin/fzf" --version)"
else
    printf "The fzf executable does not exist!\n"
fi

# Install node/nvm
printf "\nInstall/Upgrade Node/NPM and node packages\n"
export NVM_DIR="$HOME/.nvm"
rm -rf "${NVM_DIR:?}"
curl -s -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh" | bash &>/dev/null
. "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION" &>/dev/null
node -v
npm -v
# Install node packages
npm install -g tree-sitter &>/dev/null

# Install asdf/ruby/tmuxinator
printf "\nInstall ASDF, Ruby and Ruby packages\n"
ASDF_DIR="$HOME/.asdf"
rm -rf "${ASDF_DIR:?}"
git clone https://github.com/excid3/asdf.git "$ASDF_DIR" &>/dev/null
# Source asdf 
. "$HOME/.asdf/asdf.sh"
asdf plugin add ruby &>/dev/null
asdf install ruby "$RUBY_VERSION" &>/dev/null
asdf global ruby "$RUBY_VERSION" &>/dev/null
gem install tmuxinator &>/dev/null
gem update --system &>/dev/null
ruby --version
tmuxinator version

# Install Github CLI
printf "\nInstall Github CLI\n"
sudo mkdir -p -m 755 /etc/apt/keyrings && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg &> /dev/null \
&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list &> /dev/null \
&& sudo apt update &>/dev/null\
&& sudo apt install gh -y &>/dev/null
printf "%s\n" "$(gh --version)"

printf "\nBacking up files and removing existing symlinks\n"
mapfile -t files < <(find "$DIR/dotfiles" -type f)
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
printf "\nBacking up dirs and removing existing symlinks\n"
for thedir in "${DIRS[@]}"; do
    if [[ -e "$thedir" ]]; then
        if [[ -h "$thedir" ]]; then
            rm -f "$thedir"
        elif [[ -d "$thedir" ]]; then
            mv "$thedir" "$thedir-tstamp"	
	fi
    fi
done

printf "\nStow activate packages from ~/dotfiles\n"
mapfile -t packages < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d -not -name '.git')
for package in "${packages[@]}"; do
    bn="$(basename "$package")"
    stow -d "$DIR" -t "$HOME" "$bn"
done

printf "\nInstall Zim Modeles\n"
zimfw install

