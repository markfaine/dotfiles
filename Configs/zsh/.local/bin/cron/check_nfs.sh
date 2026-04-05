#!/bin/bash
MOUNT="/volume1"
TEST_FILE="$MOUNT/.nfs_write_test"
PUSH_URL="http://192.168.1.3:3001/api/push/AlRpPbwNBpzibLG8aoDjX2De9eUZHa3n"

# Test if we can write and delete a file
if touch "$TEST_FILE" 2>/dev/null && rm "$TEST_FILE"; then
  # Success: Push to Kuma
  curl -s "${PUSH_URL}?status=up&msg=NFS_Writable&ping=1" &>/dev/null
else
  # Log to syslog so you can see why it failed later, but keep cron quiet
  logger "Uptime Kuma NFS Alert: Status=$STATUS, Usage=$USAGE%, Healthy=$IS_HEALTHY"
fi
