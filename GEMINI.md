# GEMINI.md: Dotfiles Project

## Directory Overview

This repository contains personal dotfiles for a consistent development environment across Ubuntu and WSL2. The configurations are managed by Ansible and use a structure compatible with the [Tuckr](https://github.com/RaphGL/Tuckr) dotfile manager.

The primary tools configured in this repository include:

*   **Shell:** Zsh with `zim` for plugin management
*   **Terminal:** Kitty
*   **Multiplexer:** Tmux
*   **Editor:** Neovim (Lua-based configuration)
*   **Version Control:** Git
*   **Secrets Management:** Doppler

## Secrets Management with Doppler

This project uses [Doppler](https://doppler.com/) for managing secrets and environment variables.

*   The `Configs/zsh/.zshenv` file includes a `doppler-scope` function to easily switch between different Doppler configurations.
*   The `Configs/zsh/.aliases` file contains an alias `gls` that uses `doppler run` to inject secrets into a script.
*   The `Hooks/zsh/post.sh` script includes a commented-out command for downloading secrets, which can be enabled for automated setup.

## Key Files

This project is organized into two main directories: `Configs` and `Hooks`.

*   `Configs/`: Contains the actual dotfiles, organized by application.
    *   `Configs/zsh/.zshrc`: The main configuration file for the Zsh shell. It sources other files and configures the prompt, plugins, and keybindings.
    *   `Configs/zsh/.zplugins`: Defines the Zsh plugins to be loaded by `zim`.
    *   `Configs/kitty/kitty.conf`: Configuration for the Kitty terminal emulator, including fonts, themes, and key mappings.
    *   `Configs/tmux/.tmux.conf`: Configuration for the Tmux terminal multiplexer.
    *   `Configs/nvim/init.lua`: The entry point for the Neovim configuration, which is written in Lua.
    *   `Configs/git/.gitconfig`: Global Git configuration with aliases, merge tool settings, and credential helpers.
*   `Hooks/`: Contains scripts that are run at different stages of the deployment process.
    *   `Hooks/kitty/pre.sh`: A script to install Kitty and set up desktop integration.
    *   `Hooks/mise/pre.sh`: A pre-setup script for `mise`.
    *   `Hooks/zsh/post.sh`: A post-setup script for Zsh.
*   `README.md`: Provides a high-level overview of the project.

## Usage

These dotfiles are deployed using an Ansible role, as mentioned in the `README.md`. The layout is designed to be used with the Tuckr dotfile manager, which likely handles the symlinking of these configuration files to their correct locations in the user's home directory.

The `Hooks` directory suggests that there are pre- and post-installation steps for some of the applications. For example, the `kitty/pre.sh` script handles the installation of Kitty and its integration into the desktop environment.