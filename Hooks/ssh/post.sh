
## This script should follow the format of the other scripts.

# It will get the keys repository from ~/.config/ssh/config
# and create authorized_keys file in ~/.ssh/ if it doesn't already exist.

# Then it will disable the gcr-ssh-agent service for the user if it exists and is enabled.

systemctl --user mask gcr-ssh-agent.service
systemctl --user stop gcr-ssh-agent.service

# This is what is causing the duplicate agents

# Also delete ~/.config/autostart/ssh_key_agent

unset SSH_AUTH_SOCK

# When the shell is restarted the problem should not be present.
