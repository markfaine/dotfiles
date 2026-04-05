#!/bin/bash

# Get IDs of all containers with "arr" in the name
CONTAINER_IDS=$(docker ps --format '{{.ID}}' --filter "name=arr")

if [ -z "$CONTAINER_IDS" ]; then
  echo "No 'arr' containers found."
  exit 1
fi

for ID in $CONTAINER_IDS; do
  # 1. Get the Container Name
  NAME=$(docker inspect --format='{{.Name}}' $ID | sed 's/\///')

  # 2. Extract API Key directly from the container's config file
  API_KEY=$(docker exec $ID cat /config/config.xml 2>/dev/null | sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p')

  # 3. Detect Internal Port (Common defaults as fallbacks)
  PORT=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{$p}}{{end}}' $ID | sed 's/\/tcp//' | head -n 1)

  if [[ "${PORT:-}" == "" ]]; then
    case "$NAME" in
    *sonarr*) PORT="8989" ;;
    *radarr*) PORT="7878" ;;
    *bazarr*) PORT="6767" ;;
    *profilarr*) PORT="6868" ;;
    *prowlarr*) PORT="9696" ;;
    *huntarr*) PORT="9705" ;;
    *cleanuparr*) PORT="11011" ;;
    *maintainerr*) PORT="6246" ;;
    *)
      echo "Port not found"
      continue
      ;;
    esac
  fi

  if [ -n "$API_KEY" ] && [ -n "$PORT" ]; then
    echo "Starting maintenance for $NAME..."

    # Trigger the dynamic tasks (pointing to the script from our previous step)
    ./arr_tasks.sh "$API_KEY" "$PORT"

    # Wait 10 minutes between apps to let disk IO settle
    echo "Staggering... waiting 10 minutes."
    sleep 20
  else
    echo "Skipping $NAME: Could not find API Key or Port."
  fi
done
