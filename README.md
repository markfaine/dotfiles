# Dotfiles

This repository contains a collection of personal dotfiles to create a consistent and productive development environment across both Ubuntu and Ubuntu on WSL2.

## Overview

These configurations are highly customized for a workflow centered around the following tools:

*   **Shell:** Zsh with `zim` for plugin management
*   **Terminal:** Kitty
*   **Multiplexer:** Tmux
*   **Editor:** Neovim (with a modern Lua-based configuration)
*   **Version Control:** Git
*   **Secrets Management:** Doppler

The setup is designed to be automated and reproducible, using Ansible for deployment and a structure compatible with the [Tuckr](https://github.com/RaphGL/Tuckr) dotfile manager.

## Key Features

*   **Consistent Environment:** Aims to provide a seamless experience whether working on a native Linux machine or within WSL2.
*   **Modern Tooling:** Utilizes powerful and popular tools like Neovim, Kitty, and Zsh.
*   **Modular Configuration:** The Neovim setup is built with a modular Lua configuration, making it easy to extend and maintain.
*   **Automated Deployment:** Designed to be deployed via an Ansible role, ensuring a quick and easy setup on new machines.
*   **Custom Scripts and Hooks:** Includes scripts for tasks like installing applications (`kitty`) and other setup steps.

## Secrets Management with Doppler

This project uses [Doppler](https://doppler.com/) for managing secrets and environment variables.

*   The `Configs/zsh/.zshenv` file includes a `doppler-scope` function to easily switch between different Doppler configurations.
*   The `Configs/zsh/.aliases` file contains an alias `gls` that uses `doppler run` to inject secrets into a script.
*   The `Hooks/zsh/post.sh` script includes a commented-out command for downloading secrets, which can be enabled for automated setup.

## Directory Structure

The repository is organized into two main directories:

*   `Configs/`: Contains the actual dotfiles, neatly organized by application.
    *   `zsh/`: Zsh shell configuration, including plugins, aliases, and prompt settings.
    *   `kitty/`: Kitty terminal emulator settings, covering themes, fonts, and keybindings.
    *   `tmux/`: Tmux configuration for sessions, windows, and panes.
    *   `nvim/`: A comprehensive, Lua-based Neovim configuration.
    *   `git/`: Global Git settings, including aliases and credential helpers.
*   `Hooks/`: Contains scripts that are executed during the deployment process to handle tasks like application installation and setup.

## Deployment

These dotfiles are intended to be deployed by the `user` role in the [net.markfaine](httpss://github.com/markfaine/net-markfaine) Ansible collection. The directory structure is specifically laid out to be compatible with [Tuckr](https://github.com/RaphGL/Tuckr), which manages the symlinking of the configuration files to their appropriate locations in the user's home directory.

The `Hooks/` directory contains scripts that are run at different stages of the deployment to ensure that all dependencies are met and configurations are correctly applied.
