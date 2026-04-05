#!/bin/bash

# --- Configuration ---
SOURCE="/volume1/containers"
PROTON_SYNC_DIR="/volume1/backup/proton" # <-- Update this path
DATESTAMP=$(date +%Y-%m-%d)
TARGET_ARCHIVE="$PROTON_SYNC_DIR/containers-$DATESTAMP.tar.xz"
SIZE_LIMIT="+100M"

# 1. Prep Environment
mkdir -p "$PROTON_SYNC_DIR"

# 2. Generate the file list using find
# Use -not -path to exclude and -name (with -o for OR) to include
FILE_LIST=$(find "$SOURCE" -type f \
  -not -path "*/.git/*" \
  -not -path "*/*test*" \
  -not -path "*/*bak*" \
  -not -path "*/*backup*" \
  -not -path "*/*old*" \
  -not -path "*/*data*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/*venv*" \
  \( -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.toml" -o -name "*.sh" -o -name "*.py" \) \
  -printf "%P\n")

# 3. Pass that list to tar
echo "Compressing $SOURCE to $TARGET_ARCHIVE..."
echo "$FILE_LIST" | tar -cf "$TARGET_ARCHIVE" \
  --use-compress-program="xz -T0 -9" \
  -C "$SOURCE" \
  --files-from -

# 4. Generate Checksum for Cloud Verification
sha256sum "$TARGET_ARCHIVE" >"$TARGET_ARCHIVE.sha256"

# 5. The Rolling 7-Day Purge
# Deletes both the .tar.xz and the .sha256 files older than 7 days
find "$PROTON_SYNC_DIR" -maxdepth 1 -type f \( -name "containers-*.tar.xz" -o -name "containers-*.sha256" \) -mtime +7 -delete
chmod -R u+rwX,g+rwX,o+rX "$PROTON_SYNC_DIR"

echo "Done! Rolling backup synced to Proton Drive."
