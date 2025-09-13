#!/bin/bash

set -e

# --- Configuration ---
REPO_URL="https://github.com/markfaine/dotfiles.git"
BRANCH="${1:-development}" # Default to 'development' if no branch is provided

# --- Cleanup ---
cleanup() {
    echo "Cleaning up..."
    if [ ! -z "$container_id" ]; then
        docker stop "$container_id" || true
        docker rm "$container_id" || true
    fi
}
trap cleanup EXIT ERR

# Build the Docker image
echo "Building the Docker image..."
docker build -t dotfiles-test .

# Run the container
echo "Running the Docker container..."
container_id=$(docker run -d dotfiles-test)

# Function to execute commands in the container
exec_in_container() {
    docker exec "$container_id" zsh -c "$1"
}

# Clone the dotfiles repository
echo "Cloning the dotfiles repository (branch: $BRANCH)..."
exec_in_container "mkdir -p /home/testuser/.config"
exec_in_container "git clone -b $BRANCH $REPO_URL /home/testuser/.config/dotfiles"

# Remove existing zsh files
echo "Removing existing zsh files..."
exec_in_container "rm -f /home/testuser/.z*"

# Use Tuckr to set up the dotfiles and run hooks
echo "Setting up dotfiles with Tuckr..."
exec_in_container "cd /home/testuser/.config/dotfiles && tuckr set '*'"

# Run tests
echo "Running tests..."

# Test Zsh
echo "Testing Zsh..."
exec_in_container "source ~/.zshrc && which nvim"

# Test Tmux
echo "Testing Tmux..."
exec_in_container "tmux -V"
exec_in_container "test -f ~/.tmux.conf"

# Test Neovim
echo "Testing Neovim..."
exec_in_container "nvim --version"
exec_in_container "test -f ~/.config/nvim/init.lua"

# Test Git
echo "Testing Git..."
exec_in_container "git --version"
exec_in_container "test -f ~/.gitconfig"

echo "Dotfiles installation test completed successfully!"
