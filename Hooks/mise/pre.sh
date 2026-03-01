#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Mise Pre Hook
# ==============================================================================
# Ensure Node is available before first interactive shell load.

MISE_BIN="$HOME/.local/bin/mise"

if [[ ! -x "$MISE_BIN" ]]; then
	echo "Mise not installed yet. Skipping Node bootstrap."
	exit 0
fi

echo "Ensuring Node is available via mise..."
"$MISE_BIN" exec -y --silent node@latest -- node -v >/dev/null 2>&1
echo "Node bootstrap complete."

