#!/bin/bash

set -euo pipefail

docker run --rm -it ubuntu:latest \
  bash -c "apt-get update -qq && apt-get install -y -qq git curl >/dev/null 2>&1 && curl -fsSL https://raw.githubusercontent.com/markfaine/dotfiles/main/install.sh 2>/dev/null | bash"
