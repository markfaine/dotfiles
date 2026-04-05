#!/usr/bin/env bash
PUSH_URL="http://192.168.1.3:3001/api/push/ymQkMVy6YELogjwF3irOLU1gkliMFOGE"
VIP="192.168.1.100"

# Check if the IP is assigned to any interface
if ip addr show | grep -q "$VIP"; then
  # Success: This node is the VIP_MAIN. Push to Kuma.
  curl -s "$PUSH_URL?status=up&msg=VIP_MAIN"
fi
