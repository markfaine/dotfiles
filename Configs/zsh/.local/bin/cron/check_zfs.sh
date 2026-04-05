#!/bin/bash
POOL="volume1"
PUSH_URL="http://192.168.1.3:3001/api/push/dLGNvpa5NYkaEdq4g42iHj8Evnn6ubxq"

# 1. Get health status (e.g., ONLINE)
STATUS=$(zpool list -H -o health "$POOL")

# 2. Get capacity used percentage (e.g., 45)
# Using zpool list -H -o capacity provides the direct percentage
USAGE=$(zpool list -H -o capacity "$POOL" | sed 's/%//')

# 3. Check for any errors requiring a scrub or fix
ERRORS=$(zpool status -x "$POOL" | grep -c "all pools are healthy")

# Success condition: Status is ONLINE, Usage < 90%, and No errors
if [ "$STATUS" == "ONLINE" ] && [ "$USAGE" -lt 90 ] && [ "$ERRORS" -eq 0 ]; then
  curl -s "${PUSH_URL}?status=up&msg=Pool:${STATUS}_Usage:${USAGE}%&ping=${USAGE}" &>/dev/null
else
  # Log to syslog so you can see why it failed later, but keep cron quiet
  logger "Uptime Kuma ZFS Alert: Status=$STATUS, Usage=$USAGE%, Healthy=$IS_HEALTHY"
fi
