#!/bin/bash

# --- Configuration ---
STACK_SERVICE="mariadb_db" # Update to your actual Service Name
DB_USER="root"
DB_PASS="vuk34abMmd9Yi7vy"
PROTON_SYNC_DIR="/volume1/backups/proton"
DATESTAMP=$(date +%Y-%m-%d)
TARGET_FILE="$PROTON_SYNC_DIR/mariadb-export-$DATESTAMP.sql.gz"

# 1. Find the running container for this service on the local node
# docker service commands require a manager node; use docker ps with label filter instead
CONTAINER_ID=$(docker ps --filter "label=com.docker.swarm.service.name=$STACK_SERVICE" --format "{{.ID}}" | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
  echo "Error: Could not find a running container for service $STACK_SERVICE"
  exit 1
fi

# 2. Run the export and pipe it to gzip on the host
# Using --single-transaction is safer for live MariaDB backups
echo "Exporting MariaDB from $CONTAINER_ID..."
docker exec $CONTAINER_ID /usr/bin/mariadb-dump -u"$DB_USER" -p"$DB_PASS" --all-databases --single-transaction | gzip >"$TARGET_FILE"

# 3. Create Checksum
sha256sum "$TARGET_FILE" >"$TARGET_FILE.sha256"

# 4. Rolling 7-Day Purge
find "$PROTON_SYNC_DIR" -maxdepth 1 -type f \( -name "mariadb-export-*.sql.gz" -o -name "mariadb-export-*.sha256" \) -mtime +7 -delete
sudo chmod u+rwX,g+rwX,o+rX "$PROTON_SYNC_DIR"

echo "Database export saved to $TARGET_FILE"
