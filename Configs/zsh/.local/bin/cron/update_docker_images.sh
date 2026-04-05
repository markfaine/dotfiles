#!/bin/bash
set -euo pipefail

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
    log "Target: Swarm service '$swarm_service_name_label'"
    if docker service update --force --image "$image_name" "$swarm_service_name_label" >>"$LOG_FILE" 2>&1; then
      log "SUCCESS: Swarm service updated."
    else
      log "ERROR: Failed to update Swarm service."
    fi

  elif [ -n "$compose_service_name_label" ]; then
    compose_project_label=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$container_id" 2>/dev/null || echo "")
    compose_workdir_label=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$container_id" 2>/dev/null || echo "")

    log "Target: Compose project '$compose_project_label' (service: '$compose_service_name_label')"

    if [ -n "$compose_project_label" ] && [ -n "$compose_workdir_label" ]; then
      compose_args=(-p "$compose_project_label" --project-directory "$compose_workdir_label")
      [ -f "/volume1/containers/.env" ] && compose_args+=(--env-file "/volume1/containers/.env")

      # Recreate the whole project so compose handles inter-service dependencies
      if docker compose "${compose_args[@]}" up -d --force-recreate >>"$LOG_FILE" 2>&1; then
        log "SUCCESS: Compose project recreated."
      else
        log "ERROR: Failed to recreate Compose project."
      fi
    else
      log "ERROR: Missing compose project or working directory labels. Cannot recreate service."
    fi

  else
    log "Target: Standalone container '$container_name'"
    restart_policy=$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' "$container_id")
    network_mode=$(docker inspect -f '{{.HostConfig.NetworkMode}}' "$container_id")

    env_args=()
    while IFS= read -r var; do
      [[ -n "$var" ]] && env_args+=(-e "$var")
    done < <(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$container_id")

    vol_args=()
    while IFS= read -r mount; do
      [[ -n "$mount" ]] && vol_args+=(-v "$mount")
    done < <(docker inspect -f '{{range .Mounts}}{{.Source}}:{{.Destination}}{{if .Mode}}:{{.Mode}}{{end}}{{println}}{{end}}' "$container_id")

    if docker stop "$container_name" >>"$LOG_FILE" 2>&1 && \
       docker rm "$container_name" >>"$LOG_FILE" 2>&1 && \
       docker run -d \
         --name "$container_name" \
         --restart "${restart_policy:-no}" \
         --network "$network_mode" \
         "${env_args[@]}" \
         "${vol_args[@]}" \
         "$image_name" >>"$LOG_FILE" 2>&1; then
      log "SUCCESS: Standalone container recreated with new image."
    else
      log "ERROR: Failed to recreate standalone container '$container_name'."
    fi
  fi

  log "---------------------"
done

log "Docker container update check finished."
