# This is a placehodler for a script that will do the following

# Setup
# https://github.com/sakai135/wsl-vpnkit as a user systemd service
# See #fetch https://github.com/sakai135/wsl-vpnkit#setup-systemd

# If the directory /mnt/c/Users/$USER/wsl-vpnkit isn't present print a message like:
# "WSL VPN Kit isn't available to be configured.  Please download it from:
# https://github.com/sakai135/wsl-vpnkit/releases
# and import it with this command in powershell:
# wsl --import wsl-vpnkit --version 2 $env:USERPROFILE\wsl-vpnkit wsl-vpnkit.tar.gz
# then run this hook again with the command:
# cd ~/.config/dotfiles && tuckr set -fy wsl

# Configure wsl.conf file
cat <<'EOF' | sudo tee /etc/wsl.conf
[user]
default=$USER

[network]
generateResolvConf = true
generateHosts = true
hostname = "wsl"

[interop]
enabled=true
appendWindowsPath=true

[automount]
enabled=true
options="metadata"

[boot]
systemd=true
command=service cron start
EOF

cat <<'EOF' | tee /mnt/c/Users/$USER/.wslconfig
[experimental]
networkingMode=NAT
autoMemoryReclaim=gradual
sparseVhd=true
dnsTunneling=true
autoProxy=true
EOF

exit 0
