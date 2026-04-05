#!/bin/bash
set -euo pipefail

# Find the directory of this script
SCRIPT_DIR="/usr/local/bin" 
SRVCTL_PATH="$SCRIPT_DIR/srvctl"

# Log file
LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/update_docker_containers.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 1. Get all running containers
log "Starting Docker container update check..."
running_containers=$(docker ps -q)

if [ -z "$running_containers" ]; then
  log "No running containers found."
  exit 0
fi

for container_id in $running_containers; do
  # 2a. Get container info
  container_name=$(docker inspect -f '{{.Name}}' "$container_id" | sed 's,^/,,')
  image_name=$(docker inspect -f '{{.Config.Image}}' "$container_id")
  current_image_id=$(docker inspect -f '{{.Image}}' "$container_id")

  log "Checking container: '$container_name' (Image: '$image_name')"

  # 2b. Check for new image
  log "Attempting to pull latest image for '$image_name'..."
  if ! docker pull "$image_name" >/dev/null; then
    log "WARNING: Failed to pull image '$image_name'. Skipping update for this container."
    log "---------------------"
    continue
  fi

  latest_image_full_id=$(docker inspect --format='{{.Id}}' "$image_name")

  if [ "$current_image_id" == "$latest_image_full_id" ]; then
    log "Container '$container_name' is already using the latest image."
    log "---------------------"
    continue
  fi

  log "New image found for container '$container_name'."

  # 3. Determine how to restart the service
  # Check for Swarm service labels
  swarm_service_name_label=$(docker inspect -f '{{index .Config.Labels "com.docker.swarm.service.name"}}' "$container_id" 2>/dev/null || echo "")
  
  # Check for Compose service labels
  compose_service_name_label=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.service"}}' "$container_id" 2>/dev/null || echo "")

  if [ -n "$swarm_service_name_label" ]; then
    # It's a Swarm Service
    stack_name_label=$(docker inspect -f '{{index .Config.Labels "com.docker.swarm.stack.namespace"}}' "$container_id" 2>/dev/null || echo "")
    service_short_name=${swarm_service_name_label#"$stack_name_label"_}
    [ "$stack_name_label" = "$swarm_service_name_label" ] && service_short_name="$swarm_service_name_label"

    log "Target: Swarm service '$service_short_name'"
    if "$SRVCTL_PATH" update "$service_short_name" >>"$LOG_FILE" 2>&1; then
      log "SUCCESS: Swarm service updated."
    else
      log "ERROR: Failed to update Swarm service."
    fi

  elif [ -n "$compose_service_name_label" ]; then
    # It's a Compose Service
    log "Target: Compose service '$compose_service_name_label'"
    if "$SRVCTL_PATH" update "$compose_service_name_label" >>"$LOG_FILE" 2>&1; then
      log "SUCCESS: Compose service updated."
    else
      log "ERROR: Failed to update Compose service via srvctl. Attempting direct fallback..."
      
      compose_project_label=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$container_id" 2>/dev/null || echo "")
      compose_files_label=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project.config_files"}}' "$container_id" 2>/dev/null || echo "")
      if [ -n "$compose_project_label" ] && [ -n "$compose_files_label" ]; then
        COMPOSE_CMD_ARGS=""
        IFS=',' read -ra ADDR <<<"$compose_files_label"
        for f in "${ADDR[@]}"; do COMPOSE_CMD_ARGS="$COMPOSE_CMD_ARGS -f $f"; done
        ENV_FILE_PATH="/volume1/containers/.env"
        if docker compose -p "$compose_project_label" $COMPOSE_CMD_ARGS --env-file "$ENV_FILE_PATH" up -d --force-recreate "$compose_service_name_label" >>"$LOG_FILE" 2>&1; then
          log "SUCCESS: Fallback direct docker compose recreation successful."
        else
          log "CRITICAL ERROR: Fallback direct docker compose recreation failed."
        fi
      fi
    fi
  else
    # Not Swarm or Compose - Try Standalone update via srvctl
    log "Target: Standalone container '$container_name'"
    if "$SRVCTL_PATH" update "$container_name" >>"$LOG_FILE" 2>&1; then
      log "SUCCESS: Standalone container updated."
    else
      log "WARNING: Container '$container_name' could not be updated by srvctl. Manual intervention may be required."
    fi
  fi

  log "---------------------"
done

log "Docker container update check finished."
