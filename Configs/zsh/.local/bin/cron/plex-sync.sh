#!/bin/bash

# Configuration
PRIMARY_IP="192.168.1.3"
SECONDARY_IP="192.168.1.5"
NFS_MOUNT="/volume1/plex/Plex Media Server"
PLEX_DATA_DIR="/var/lib/plex/Plex Media Server"

# 1. Stop Plex on Primary
echo "Stopping Plex on Primary..."
sudo systemctl stop plexmediaserver

# 2. Rsync from Primary to NFS
# Added excludes for temporary/cache data to speed up the sync
echo "Syncing Primary to NFS..."
sudo rsync -avz --delete \
  --exclude='Cache/*' \
  --exclude='Logs/*' \
  --exclude='Transcode/*' \
  --exclude='Drivers/*' \
  "$PLEX_DATA_DIR/" "$NFS_MOUNT/"

# 3. Start Plex on Primary
echo "Starting Plex on Primary..."
sudo systemctl start plexmediaserver

# 4. Stop Plex on Secondary
echo "Stopping Plex on Secondary..."
ssh -i /usr/lib/plexmediaserver/.ssh/id_ed25519 "plex@$SECONDARY_IP" "sudo /usr/bin/systemctl stop plexmediaserver"

# 5. Rsync from NFS to Secondary
echo "Syncing NFS to Secondary..."
rsync -avz --delete -e "ssh -i /usr/lib/plexmediaserver/.ssh/id_ed25519" "$NFS_MOUNT/" "plex@$SECONDARY_IP:$PLEX_DATA_DIR/"

# 6. Start Plex on Secondary
echo "Starting Plex on Secondary..."
ssh -i /usr/lib/plexmediaserver/.ssh/id_ed25519 "plex@$SECONDARY_IP" "sudo /usr/bin/systemctl start plexmediaserver"

echo "Sync Complete."
