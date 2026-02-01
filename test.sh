#!/bin/bash

set -e

# --- Configuration ---
REPO_URL="https://github.com/markfaine/dotfiles.git"
BRANCH="${1:-development}" # Default to 'development' if no branch is provided
USERNAME="mfaine"
GH_TOKEN="$(gh auth token)"
export GH_TOKEN

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
docker build -t dotfiles-test --build-arg GH_TOKEN="$GH_TOKEN" .

# Run the container
echo "Running the Docker container..."
container_id=$(docker run -d dotfiles-test)

# Function to execute commands in the container
exec_in_container() {
  docker exec "$container_id" zsh -c "$1"
}

# Clone the dotfiles repository
echo "Cloning the dotfiles repository (branch: $BRANCH)..."
exec_in_container "mkdir -p /home/$USERNAME/.config/mise"
exec_in_container "git clone -b $BRANCH $REPO_URL /home/$USERNAME/.config/dotfiles"
exec_in_container "cp -f /home/$USERNAME/.config/dotfiles/Configs/mise/.config/mise/config.toml /home/$USERNAME/.config/mise/config.toml"
exec_in_container "eval "$(mise activate zsh)""
exec_in_container "mise use node@latest"
#exec_in_container "mise use rust@latest"

# Use Tuckr to set up the dotfiles and run hooks
#echo "Setting up dotfiles with Tuckr..."
#exec_in_container "cd /home/$USERNAME/.config/dotfiles && tuckr set \*"

# Dump user into bash shell
docker exec -it "$container_id" /bin/bash
