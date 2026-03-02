# SSH Agent Troubleshooting & Optimization Guide

This guide provides a structured checklist for identifying and resolving "multiplying" `ssh-agent` processes and conflicting agent services on modern Linux systems (Wayland or X11).

---

## 📋 The Troubleshooting Checklist

### 1. The "Custom Shell" Layer (User Config)
The most common cause of duplicate processes is a shell configuration that spawns a new agent for every terminal window instead of reusing an existing one.
- [ ] **Files to Check**: `.zshrc`, `.bashrc`, `.zshenv`, and `.zprofile`.
- [ ] **Pattern to Find**: `eval $(ssh-agent)` or `ssh-agent -s`.
- [ ] **The Fix**: Use a **Singleton Script** that writes the agent's PID to a file (e.g., `~/.ssh/agent.env`) and checks if that PID is still running before starting a new one.

### 2. The "Systemd User" Layer
Modern distributions use **Socket Activation**, which automatically restarts an agent the moment an app (like Kitty) looks for an SSH key.
- [ ] **Identify Units**: Run `systemctl --user list-units | grep ssh`.
- [ ] **Common Conflicts**:
    - `ssh-agent.socket` (Default OpenSSH)
    - `gpg-agent-ssh.socket` (GnuPG emulation)
    - `gcr-ssh-agent.socket` (GNOME Keyring wrapper)
- [ ] **The Fix**: Use `systemctl --user mask <unit>` to permanently block these from auto-starting.

### 3. The "Legacy Desktop" Layer (GUI Login)
Even on Wayland, many Display Managers (GDM, SDDM, LightDM) source legacy X11 scripts that export an agent globally.
- [ ] **Config File**: `/etc/X11/Xsession.options`.
- [ ] **Pattern to Find**: `use-ssh-agent`.
- [ ] **The Fix**: Change the line to `no-use-ssh-agent` and reboot. This prevents a "Global Ghost" agent from being the parent of all your user apps.

### 4. The "Environment Inheritance" Layer
If the `systemd --user` manager inherits a stale `SSH_AUTH_SOCK` variable during login, every app it launches (like Kitty) will be "infected" with that specific socket.
- [ ] **Check Manager**: `systemctl --user show-environment | grep SSH`.
- [ ] **The Fix**: Run `systemctl --user unset-environment SSH_AUTH_SOCK` to wipe the inherited variable from the systemd session.

---

## 🛠️ The Singleton Script (For `.zshrc` / `.bashrc`)
This script handles **YubiKey detection**, **SSH Config priority**, and **Process Reuse** in one block.

```bash
# Define environment file
SSH_ENV="$HOME/.ssh/agent.env"

function start_agent {
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
}

# 1. Manage the Agent Process (Singleton)
if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent > /dev/null || start_agent
else
    start_agent
fi

# 2. Conditional Key Loading (Hardware vs File)
load_ssh_identities() {
    # Case: YubiKey Presence (Vendor ID 1050)
    if lsusb 2>/dev/null | grep -q "1050" || system_profiler SPUSBDataType 2>/dev/null | grep -q "Yubico"; then
        ssh-add -K 2>/dev/null
    fi

    # Case: IdentityFile from Config or Fallback to id_rsa
    local CONFIG_KEY=$(grep -m1 "IdentityFile" "$HOME/.ssh/config" | awk '{print $2}' | sed "s|^~|$HOME|")
    local TARGET_KEY="${CONFIG_KEY:-$HOME/.ssh/id_rsa}"

    if [[ -f "$TARGET_KEY" ]]; then
        local FINGERPRINT=$(ssh-keygen -lf "$TARGET_KEY" | awk '{print $2}')
        if ! ssh-add -l | grep -q "$FINGERPRINT"; then
            ssh-add "$TARGET_KEY"
        fi
    fi
}
load_ssh_identities
