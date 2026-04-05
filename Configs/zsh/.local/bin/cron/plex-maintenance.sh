#!/bin/bash

################################################################################
# Plex Maintenance Script
#
# This script performs comprehensive Plex maintenance tasks in an optimized order:
# 1. Stop Plex, rsync database backup, check/install updates, restart Plex
# 2. Trigger database backup via API (and copy to backup location)
# 3. Optimize database via API
# 4. Cleanup old bundles via API
# 5. Plex media analysis, audio analysis, cache cleanup, library refresh
# 6. Start Kometa container for metadata management
# 7. Sync up-to-date Plex data to NFS and remote secondary server
#
# Usage: Run via cron (e.g., daily at 3 AM)
# Example crontab entry: 0 3 * * * /home/mfaine/projects/plex/plex-maintenance.sh
################################################################################

set -euo pipefail

# Configuration
PLEX_SERVER="127.0.0.1"
PLEX_PORT="32400"
PLEX_TOKEN="sVD35zGYmxc4b5NgDb9g" # REQUIRED: Set your Plex token here or via environment variable
PLEX_ROOT_DIR="/var/lib/plex/Plex Media Server"
PLEX_SOURCE_DIR="$PLEX_ROOT_DIR"
PLEX_BACKUP_DIR="/volume1/plex/Plex Media Server"
PLEX_EXCLUDES=("Cache/" "Crash Reports/" "Diagnostics/" "Drivers/" "Logs/" "Media/" "Metadata/" "Plug-in Support/Caches/" "Scanners/" "Updates/")
PLEX_DB_BACKUP_TARGET="/volume1/plex/backup/"
KOMETA_DIR="/volume1/containers/docker/kometa"
PLEX_SCANNER="/usr/lib/plexmediaserver/Plex Media Scanner"
LOG_FILE="/var/log/plex-maintenance.log"
SECONDARY_IP="192.168.1.5"
SSH_KEY="/usr/lib/plexmediaserver/.ssh/id_ed25519"
SYNC_EXCLUDES=("Cache/" "Logs/" "Transcode/" "Drivers/")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# Logging Functions
################################################################################

log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

################################################################################
# Validation Functions
################################################################################

check_requirements() {
  log "Checking requirements..."

  # Check if running as root or with sudo privileges
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root or with sudo"
    exit 1
  fi

  # Check for required commands
  local required_commands=("curl" "rsync" "systemctl" "docker" "ssh")
  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "Required command not found: $cmd"
      exit 1
    fi
  done

  # Check if Plex token is set
  if [[ -z "${PLEX_TOKEN}" ]]; then
    log_error "PLEX_TOKEN is not set. Please set it in the script or as an environment variable"
    log_error "To get your token, visit: https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/"
    exit 1
  fi

  # Check if directories exist
  if [[ ! -d "${PLEX_SOURCE_DIR}" ]]; then
    log_error "Plex source directory not found: ${PLEX_SOURCE_DIR}"
    exit 1
  fi

  if [[ ! -d "${KOMETA_DIR}" ]]; then
    log_warning "Kometa compose directory not found: ${KOMETA_DIR}"
  fi

  log_success "All requirements met"
}

################################################################################
# Plex API Functions
################################################################################

plex_api_call() {
  local endpoint="$1"
  local method="${2:-GET}"
  local response
  local http_code

  response=$(curl -s -w "\n%{http_code}" -X "$method" \
    "http://${PLEX_SERVER}:${PLEX_PORT}${endpoint}?X-Plex-Token=${PLEX_TOKEN}")

  http_code=$(echo "$response" | tail -n1)

  echo "$http_code"
}

check_plex_activity() {
  log "Checking for active Plex sessions..."

  local http_code
  http_code=$(curl -s -w "%{http_code}" -o /dev/null \
    "http://${PLEX_SERVER}:${PLEX_PORT}/status/sessions?X-Plex-Token=${PLEX_TOKEN}")

  if [[ "$http_code" == "200" ]]; then
    local sessions
    sessions=$(curl -s "http://${PLEX_SERVER}:${PLEX_PORT}/status/sessions?X-Plex-Token=${PLEX_TOKEN}" |
      grep -c "<Video" || true)

    if [[ "$sessions" -gt 0 ]]; then
      log_warning "Found $sessions active session(s)"
      return 1
    fi
  fi

  log "No active sessions detected"
  return 0
}

################################################################################
# Main Maintenance Tasks
################################################################################

task_1_backup_and_update() {
  log "==== TASK 1: Backup Database and Update Plex ===="

  # Check for active sessions
  if ! check_plex_activity; then
    log_warning "Active sessions detected. Consider running during off-peak hours."
    log "Waiting 30 seconds for sessions to complete..."
    sleep 30

    if ! check_plex_activity; then
      log_error "Still active sessions. Aborting to prevent interruption."
      exit 1
    fi
  fi

  # Stop Plex Media Server
  log "Stopping Plex Media Server..."
  systemctl stop plexmediaserver
  sleep 5

  # Verify Plex is stopped
  if systemctl is-active --quiet plexmediaserver; then
    log_error "Failed to stop Plex Media Server"
    exit 1
  fi
  log_success "Plex Media Server stopped"

  # Rsync database to backup directory
  log "Syncing Plex database to backup location..."
  mkdir -p "${PLEX_BACKUP_DIR}"

  tmp_excludes_file=$(mktemp)
  for p in "${PLEX_EXCLUDES[@]}"; do
    printf '%s\n' "$p" >>"$tmp_excludes_file"
  done
  if rsync -avh --exclude-from="$tmp_excludes_file" --delete "${PLEX_SOURCE_DIR}/" "${PLEX_BACKUP_DIR}/"; then
    log_success "Database synced successfully"
  else
    log_error "Failed to sync database"
    # Start Plex even if backup fails
    rm -f "$tmp_excludes_file"
    systemctl start plexmediaserver
    exit 1
  fi
  rm -f "$tmp_excludes_file"

  # Check for and install Plex updates
  log "Checking for Plex updates..."
  if [[ -f "${PLEXUPDATE_SCRIPT}" ]]; then
    if sudo "${PLEXUPDATE_SCRIPT}" --config "${PLEXUPDATE_CONFIG}"; then
      log_success "Plex update check completed"
    else
      log_warning "Plex update check returned non-zero exit code"
    fi
  else
    log_warning "Plexupdate script not found at ${PLEXUPDATE_SCRIPT}"
  fi

  # Start Plex Media Server
  log "Starting Plex Media Server..."
  systemctl start plexmediaserver

  # Wait for Plex to be ready
  log "Waiting for Plex to start (up to 60 seconds)..."
  local count=0
  while [[ $count -lt 12 ]]; do
    if systemctl is-active --quiet plexmediaserver; then
      sleep 5
      local http_code
      http_code=$(curl -s -w "%{http_code}" -o /dev/null \
        "http://${PLEX_SERVER}:${PLEX_PORT}/identity?X-Plex-Token=${PLEX_TOKEN}")

      if [[ "$http_code" == "200" ]]; then
        log_success "Plex Media Server is running and responding"
        return 0
      fi
    fi
    sleep 5
    ((count++))
  done

  log_error "Plex Media Server failed to start properly"
  exit 1
}

task_2_api_database_backup() {
  log "==== TASK 2: Trigger API Database Backup ===="

  local http_code
  http_code=$(plex_api_call "/butler/BackupDatabase" "POST")

  if [[ "$http_code" == "200" ]]; then
    log_success "Database backup task started"
  elif [[ "$http_code" == "202" ]]; then
    log_warning "Database backup task already running"
  else
    log_error "Failed to start database backup (HTTP $http_code)"
    return 1
  fi

  # Wait for backup to complete (check every 10 seconds for up to 5 minutes)
  log "Waiting for backup to complete..."
  sleep 30

  # Copy database backup files to target directory
  log "Copying database backups to ${PLEX_DB_BACKUP_TARGET}..."
  mkdir -p "${PLEX_DB_BACKUP_TARGET}"

  local db_dir="${PLEX_SOURCE_DIR}/Plug-in Support/Databases"
  if [[ -d "$db_dir" ]]; then
    # Copy all dated backup files
    if find "$db_dir" -name "*.db-20*" -type f -mtime -1 -exec cp {} "${PLEX_DB_BACKUP_TARGET}/" \; 2>/dev/null; then
      log_success "Database backup files copied"
    else
      log_warning "No recent backup files found to copy"
    fi
  else
    log_error "Database directory not found: $db_dir"
  fi
}

task_3_optimize_database() {
  log "==== TASK 3: Optimize Database ===="

  local http_code
  http_code=$(plex_api_call "/library/optimize" "PUT")

  if [[ "$http_code" == "200" ]]; then
    log_success "Database optimization started"
    log "Optimization is running in the background (this may take several minutes)"
  else
    log_error "Failed to start database optimization (HTTP $http_code)"
    return 1
  fi
}

task_4_cleanup_bundles() {
  log "==== TASK 4: Cleanup Old Bundles ===="

  local http_code
  http_code=$(plex_api_call "/butler/CleanOldBundles" "POST")

  if [[ "$http_code" == "200" ]]; then
    log_success "Bundle cleanup task started"
  elif [[ "$http_code" == "202" ]]; then
    log_warning "Bundle cleanup task already running"
  else
    log_error "Failed to start bundle cleanup (HTTP $http_code)"
    return 1
  fi
}

task_5_plex_analysis() {
  log "==== TASK 5: Plex Analysis ===="

  # Deep analysis and marker/thumbnail generation via Scanner CLI
  if [[ -f "${PLEX_SCANNER}" ]]; then
    log "Running deep media analysis..."
    export LD_LIBRARY_PATH=/usr/lib/plexmediaserver
    if "${PLEX_SCANNER}" --analyze --index --manual; then
      log_success "Media analysis completed"
    else
      log_warning "Media analysis returned non-zero exit code"
    fi
  else
    log_warning "Plex Media Scanner not found at ${PLEX_SCANNER}, skipping analysis"
  fi

  # Audio analysis (loudness & sonic) via Butler API
  local http_code
  http_code=$(plex_api_call "/butler/AudioAnalysis" "POST")
  if [[ "$http_code" == "200" ]]; then
    log_success "Audio analysis task started"
  elif [[ "$http_code" == "202" ]]; then
    log_warning "Audio analysis task already running"
  else
    log_error "Failed to start audio analysis (HTTP $http_code)"
  fi

  # Remove old transcode sync cache files
  local cache_dir="${PLEX_ROOT_DIR}/Cache/Transcode/Sync"
  if [[ -d "${cache_dir}" ]]; then
    log "Clearing transcode sync cache..."
    if rm -rf "${cache_dir:?}/"*; then
      log_success "Transcode sync cache cleared"
    else
      log_warning "Failed to clear transcode sync cache"
    fi
  else
    log_warning "Transcode sync cache directory not found, skipping: ${cache_dir}"
  fi

  # Trigger library scan for all sections
  http_code=$(plex_api_call "/library/sections/all/refresh" "GET")
  if [[ "$http_code" == "200" ]]; then
    log_success "Library refresh triggered"
  else
    log_error "Failed to trigger library refresh (HTTP $http_code)"
    return 1
  fi
}

task_6_start_kometa() {  log "==== TASK 6: Start Kometa Container ===="

  if [[ ! -d "${KOMETA_DIR}" ]]; then
    log_warning "Kometa directory not found, skipping"
    return 0
  fi

  cd "${KOMETA_DIR}" || {
    log_error "Failed to change to Kometa directory"
    return 1
  }

  # Check if docker-compose or docker compose command exists
  if command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
  elif docker compose version &>/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
  else
    log_error "Neither docker-compose nor docker compose command found"
    return 1
  fi

  log "Starting Kometa container..."
  if /volume1/containers/docker/kometa/kometa_run_now.sh; then
    log_success "Kometa container started"
  else
    log_error "Failed to start Kometa container"
    return 1
  fi
}

task_7_sync_to_secondary() {
  log "==== TASK 7: Sync Plex Data to NFS and Secondary Server ===="

  # Check for active sessions before stopping Plex
  if ! check_plex_activity; then
    log_warning "Active sessions detected. Waiting 60 seconds before syncing..."
    sleep 60
    if ! check_plex_activity; then
      log_error "Still active sessions. Skipping sync to avoid interruption."
      return 1
    fi
  fi

  # Stop Plex to ensure a consistent snapshot for sync
  log "Stopping Plex Media Server for sync..."
  systemctl stop plexmediaserver
  sleep 5

  if systemctl is-active --quiet plexmediaserver; then
    log_error "Failed to stop Plex Media Server"
    return 1
  fi
  log_success "Plex Media Server stopped"

  # Rsync Primary → NFS (PLEX_BACKUP_DIR serves as NFS mount)
  log "Syncing Primary to NFS (${PLEX_BACKUP_DIR})..."
  mkdir -p "${PLEX_BACKUP_DIR}"

  local tmp_excludes
  tmp_excludes=$(mktemp)
  for p in "${SYNC_EXCLUDES[@]}"; do
    printf '%s\n' "$p" >>"$tmp_excludes"
  done

  if rsync -avz --delete --exclude-from="$tmp_excludes" "${PLEX_SOURCE_DIR}/" "${PLEX_BACKUP_DIR}/"; then
    log_success "Primary → NFS sync complete"
  else
    log_error "Primary → NFS sync failed"
    rm -f "$tmp_excludes"
    systemctl start plexmediaserver
    return 1
  fi
  rm -f "$tmp_excludes"

  # Restart Plex on Primary before syncing to secondary
  log "Starting Plex Media Server on Primary..."
  systemctl start plexmediaserver

  local count=0
  while [[ $count -lt 12 ]]; do
    if systemctl is-active --quiet plexmediaserver; then
      local http_code
      http_code=$(curl -s -w "%{http_code}" -o /dev/null \
        "http://${PLEX_SERVER}:${PLEX_PORT}/identity?X-Plex-Token=${PLEX_TOKEN}")
      if [[ "$http_code" == "200" ]]; then
        log_success "Plex Media Server restarted on Primary"
        break
      fi
    fi
    sleep 5
    ((count++))
  done

  if [[ $count -ge 12 ]]; then
    log_error "Plex failed to restart on Primary after sync"
    return 1
  fi

  # Stop Plex on Secondary
  log "Stopping Plex on Secondary (${SECONDARY_IP})..."
  if ssh -i "${SSH_KEY}" "plex@${SECONDARY_IP}" "sudo /usr/bin/systemctl stop plexmediaserver"; then
    log_success "Plex stopped on Secondary"
  else
    log_error "Failed to stop Plex on Secondary"
    return 1
  fi

  # Rsync NFS → Secondary
  log "Syncing NFS to Secondary (${SECONDARY_IP})..."
  if rsync -avz --delete -e "ssh -i ${SSH_KEY}" "${PLEX_BACKUP_DIR}/" "plex@${SECONDARY_IP}:${PLEX_SOURCE_DIR}/"; then
    log_success "NFS → Secondary sync complete"
  else
    log_error "NFS → Secondary sync failed"
    ssh -i "${SSH_KEY}" "plex@${SECONDARY_IP}" "sudo /usr/bin/systemctl start plexmediaserver" || true
    return 1
  fi

  # Start Plex on Secondary
  log "Starting Plex on Secondary (${SECONDARY_IP})..."
  if ssh -i "${SSH_KEY}" "plex@${SECONDARY_IP}" "sudo /usr/bin/systemctl start plexmediaserver"; then
    log_success "Plex started on Secondary"
  else
    log_error "Failed to start Plex on Secondary"
    return 1
  fi

  log_success "Sync to Secondary complete"
}

################################################################################
# Main Script Execution
################################################################################

main() {
  log "========================================"
  log "Plex Maintenance Script Started"
  log "========================================"

  # Check requirements
  check_requirements

  # Execute tasks in order
  task_1_backup_and_update
  task_2_api_database_backup
  task_3_optimize_database
  task_4_cleanup_bundles
  task_5_plex_analysis
  task_6_start_kometa
  task_7_sync_to_secondary

  log "========================================"
  log_success "All maintenance tasks completed!"
  log "========================================"
}

# Run main function
main "$@"
