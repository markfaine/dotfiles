#!/bin/bash
set +euo pipefail

# For testing or if the user account does not already exist, create it

user="${1:-mfaine}"
id="$(cat /etc/group /etc/passwd | cut -d ":" -f 3 | grep "^1...$" | sort -n | tail -n 1 | awk '{ print $1+1 }')"

if [[ "${id}x" == "x" ]]; then
    printf "No suitable uid/gid found in range, attempting to use 1000\n"
    id=1000
fi

apt update && apt install -y sudo zsh &>/dev/null
groupadd --gid "$id" "$user"
useradd -rm -d "/home/$user" -s /bin/bash -g "$user" -G sudo -u "$id" "$user"
echo "$user ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$user"


# Change the shell to zsh, and install zim
printf "\nSetting the default shell to zsh for $s\n" "$user"
if [[ ! "$SHELL" =~ "zsh" ]]; then
    chsh -s "$(command -v zsh)" "$user" 
fi

