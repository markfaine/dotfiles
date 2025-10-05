# Hooks Directory

This directory contains scripts that are executed during the dotfiles deployment process. These hooks are designed to handle tasks such as application installation, configuration setup, and post-deployment tasks that cannot be managed through simple file symlinking.

## Hook Types

- **pre.sh**: Scripts run **before** the dotfiles are symlinked into place. Typically used for installing applications or preparing the environment.
- **post.sh**: Scripts run **after** the dotfiles are symlinked. Used for final configuration, plugin syncing, or environment setup.

Hooks are executed by the deployment tool (e.g., Tuckr or the Ansible role in `net.markfaine`). Ensure scripts are idempotent and handle errors gracefully.

## Scripts Overview

### `kitty/pre.sh`
- **Purpose**: Installs Kitty terminal emulator and sets up desktop integration.
- **When**: Runs before Kitty configs are symlinked.
- **Details**: Downloads and installs Kitty via the official installer, creates symbolic links for PATH, and configures desktop files for Linux integration (e.g., menus, file associations).
- **Dependencies**: Requires `curl`, assumes `~/.local/bin` is in PATH.
- **Idempotency**: Checks for existing installation before proceeding.

### `mise/pre.sh`
- **Purpose**: Prepares Mise (a tool version manager) by removing any existing config to avoid conflicts.
- **When**: Runs before Mise configs are symlinked.
- **Details**: Removes `~/.config/mise/config.toml` if it exists, ensuring a clean state for dotfile-managed configuration.
- **Why**: Prevents merge issues or overrides from previous setups.
- **Idempotency**: Safe to run multiple times.

### `nvim/post.sh`
- **Purpose**: Syncs Neovim plugins using Lazy.
- **When**: Runs after Neovim configs are symlinked.
- **Details**: Runs Neovim in headless mode to install/update plugins via Lazy.
- **Dependencies**: Requires Neovim with Lazy plugin manager configured in `init.lua`.
- **Idempotency**: Lazy handles updates incrementally.

### `zsh/post.sh`
- **Purpose**: Sets up Doppler for secrets management.
- **When**: Runs after Zsh configs are symlinked.
- **Details**: Executes a setup script for Doppler environment variables if available.
- **Dependencies**: Requires `~/.local/bin/setup-doppler-env.sh` to exist.
- **Idempotency**: Checks for script existence before running.

## Best Practices

- **Error Handling**: Scripts use `set -euo pipefail` for strict error checking.
- **Logging**: Include `echo` statements for progress tracking.
- **Testing**: Test hooks in a safe environment before deployment.
- **Adding New Hooks**: Create `pre.sh` or `post.sh` in a new subdirectory (e.g., `newtool/pre.sh`) following the same structure.

## Troubleshooting

- If a hook fails, check logs for error messages.
- Ensure dependencies (e.g., `curl`, Neovim) are installed.
- Run hooks manually for debugging: `bash Hooks/tool/hook.sh`.