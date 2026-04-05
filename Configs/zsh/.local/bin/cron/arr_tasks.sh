#!/bin/bash
API_KEY=$1
PORT=$2
HOST="192.168.1.5"

# 1. Get command history
# 2. Filter for entries where trigger is "scheduled"
# 3. Get the 'name' and ensure it's unique
TASKS=$(curl -s "http://$HOST:$PORT/api/v3/command?apiKey=$API_KEY" | jq -r '.[] | select(.trigger == "scheduled") | .name' | sort -u)

if [ -z "$TASKS" ]; then
  echo "  [!] No previously scheduled tasks found in history for $PORT."
  exit 0
fi

for TASK in $TASKS; do
  # Only trigger the ones that actually spin up the disks
  if [[ "$TASK" =~ (Refresh|Rescan|Backup|Process|Check) ]]; then
    echo "  -> Re-triggering scheduled task: $TASK"
    curl -s -X POST "http://$HOST:$PORT/api/v3/command" \
      -H "Content-Type: application/json" \
      -H "X-Api-Key: $API_KEY" \
      -d "{\"name\": \"$TASK\"}"
  fi
done
