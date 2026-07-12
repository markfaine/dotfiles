#!/bin/bash

################################################################################
# Plex Maintenance Script
#
# This script performs comprehensive Plex maintenance tasks in an optimized order:
# 1. Stop Plex, rsync database backup, restart Plex
# 2. Trigger database backup via API (and copy to backup location)
# 3. Plex media analysis, audio analysis, cache cleanup, library refresh
# 4. Start Kometa container for metadata management
# 5. Cleanup old bundles via API
# 6. Optimize database via API
# 7. Sync up-to-date Plex data to NFS and remote secondary server
#
# Usage:
#   /home/mfaine/projects/plex/plex-maintenance.sh              # default: run all jobs
#   /home/mfaine/projects/plex/plex-maintenance.sh run refresh-library optimize-db
#   /home/mfaine/projects/plex/plex-maintenance.sh group online-maintenance
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
# Job Definitions
################################################################################

ALL_JOBS=("cold-backup" "db-backup" "analysis" "kometa" "cleanup-bundles" "optimize-db" "sync-secondary" "upgrade")
JOB_ORDER=("cold-backup" "db-backup" "analysis" "refresh-library" "kometa" "cleanup-bundles" "optimize-db" "sync-secondary" "upgrade")

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
  local selected_jobs=("$@")
  log "Checking requirements..."

  # Check if running as root or with sudo privileges
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root or with sudo"
    exit 1
  fi

  local -A required_commands=()
  local needs_plex_token=0
  local needs_plex_source_dir=0
  local needs_ssh_key=0
  local needs_kometa_dir=0
  local job
  local cmd

  for job in "${selected_jobs[@]}"; do
    case "$job" in
    cold-backup)
      required_commands["curl"]=1
      required_commands["rsync"]=1
      required_commands["systemctl"]=1
      needs_plex_token=1
      needs_plex_source_dir=1
      ;;
    db-backup | cleanup-bundles | optimize-db)
      required_commands["curl"]=1
      needs_plex_token=1
      needs_plex_source_dir=1
      ;;
    refresh-library)
      required_commands["curl"]=1
      needs_plex_token=1
      ;;
    analysis)
      required_commands["curl"]=1
      needs_plex_token=1
      needs_plex_source_dir=1
      ;;
    kometa)
      required_commands["docker"]=1
      needs_kometa_dir=1
      ;;
    sync-secondary)
      required_commands["curl"]=1
      required_commands["rsync"]=1
      required_commands["ssh"]=1
      required_commands["systemctl"]=1
      needs_plex_token=1
      needs_plex_source_dir=1
      needs_ssh_key=1
      ;;
    esac
  done

  # Check for required commands for the selected jobs
  for cmd in "${!required_commands[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "Required command not found: $cmd"
      exit 1
    fi
  done

  # Check if Plex token is set for Plex operations
  if [[ "$needs_plex_token" -eq 1 && -z "${PLEX_TOKEN}" ]]; then
    log_error "PLEX_TOKEN is not set. Please set it in the script or as an environment variable"
    log_error "To get your token, visit: https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/"
    exit 1
  fi

  if [[ "$needs_plex_source_dir" -eq 1 && ! -d "${PLEX_SOURCE_DIR}" ]]; then
    log_error "Plex source directory not found: ${PLEX_SOURCE_DIR}"
    exit 1
  fi

  if [[ "$needs_ssh_key" -eq 1 && ! -f "${SSH_KEY}" ]]; then
    log_error "SSH key not found: ${SSH_KEY}"
    exit 1
  fi

  if [[ "$needs_kometa_dir" -eq 1 && ! -d "${KOMETA_DIR}" ]]; then
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

get_plex_activity_count() {
  local response
  local http_code
  local body
  local activity_count

  response=$(curl -s -w "\n%{http_code}" \
    "http://${PLEX_SERVER}:${PLEX_PORT}/activities?X-Plex-Token=${PLEX_TOKEN}")

  http_code=${response##*$'\n'}
  body=${response%$'\n'*}

  if [[ "$http_code" != "200" ]]; then
    log_error "Failed to query Plex activities (HTTP $http_code)"
    return 1
  fi

  activity_count=$(printf '%s' "$body" | grep -o "<Activity" | wc -l | tr -d '[:space:]')
  echo "${activity_count:-0}"
}

wait_for_plex_background_tasks() {
  local task_name="$1"
  local timeout_seconds="${2:-1800}"
  local interval_seconds="${3:-15}"
  local elapsed=0

  log "Waiting for ${task_name} to complete..."

  while [[ $elapsed -lt $timeout_seconds ]]; do
    local activity_count
    activity_count=$(get_plex_activity_count) || return 1

    if [[ "$activity_count" -eq 0 ]]; then
      log_success "${task_name} completed"
      return 0
    fi

    log "Plex still has ${activity_count} background task(s) running..."
    sleep "$interval_seconds"
    ((elapsed += interval_seconds))
  done

  log_error "Timed out waiting for ${task_name} to complete"
  return 1
}

wait_for_plex_ready() {
  local timeout_seconds="${1:-60}"
  local interval_seconds=5
  local elapsed=0

  log "Waiting for Plex to start (up to ${timeout_seconds} seconds)..."

  while [[ $elapsed -lt $timeout_seconds ]]; do
    if systemctl is-active --quiet plexmediaserver; then
      local http_code
      http_code=$(curl -s -w "%{http_code}" -o /dev/null \
        "http://${PLEX_SERVER}:${PLEX_PORT}/identity?X-Plex-Token=${PLEX_TOKEN}")

      if [[ "$http_code" == "200" ]]; then
        log_success "Plex Media Server is running and responding"
        return 0
      fi
    fi

    sleep "$interval_seconds"
    ((elapsed += interval_seconds))
  done

  log_error "Plex Media Server failed to start properly"
  return 1
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

join_by() {
  local delimiter="$1"
  shift || true

  if [[ $# -eq 0 ]]; then
    echo ""
    return 0
  fi

  local joined="$1"
  shift

  local item
  for item in "$@"; do
    joined+="${delimiter}${item}"
  done

  echo "$joined"
}

job_description() {
  case "$1" in
  cold-backup) echo "Stop Plex, take a cold rsync snapshot, and restart Plex" ;;
  db-backup) echo "Trigger Plex database backup and copy backup files" ;;
  analysis) echo "Run analysis, audio analysis, cache cleanup, and library refresh" ;;
  refresh-library) echo "Trigger a library refresh without running full analysis" ;;
  kometa) echo "Run the Kometa metadata container" ;;
  cleanup-bundles) echo "Trigger old bundle cleanup and wait for completion" ;;
  optimize-db) echo "Optimize the Plex database and wait for completion" ;;
  sync-secondary) echo "Sync Plex data to NFS and the secondary server" ;;
  *) return 1 ;;
  esac
}

group_description() {
  case "$1" in
  all) echo "Run every maintenance job in the canonical order" ;;
  online-maintenance) echo "Run online-safe maintenance jobs while Plex stays up" ;;
  cold-maintenance) echo "Run cold-copy jobs that stop Plex" ;;
  metadata) echo "Run metadata-oriented jobs" ;;
  database) echo "Run database backup and optimization jobs" ;;
  *) return 1 ;;
  esac
}

is_valid_job() {
  case "$1" in
  cold-backup | db-backup | analysis | refresh-library | kometa | cleanup-bundles | optimize-db | sync-secondary) return 0 ;;
  *) return 1 ;;
  esac
}

expand_group() {
  case "$1" in
  all) printf '%s\n' "${ALL_JOBS[@]}" ;;
  online-maintenance) printf '%s\n' "db-backup" "analysis" "kometa" "cleanup-bundles" "optimize-db" ;;
  cold-maintenance) printf '%s\n' "cold-backup" "sync-secondary" ;;
  metadata) printf '%s\n' "analysis" "kometa" ;;
  database) printf '%s\n' "db-backup" "optimize-db" ;;
  *) return 1 ;;
  esac
}

print_usage() {
  printf '%s\n' "Usage:"
  printf '%s\n' "  $0                       Run all jobs (default; keeps existing cron entries working)"
  printf '%s\n' "  $0 all                   Run all jobs"
  printf '%s\n' "  $0 run <job> [job...]    Run one or more jobs in canonical order"
  printf '%s\n' "  $0 group <group> [...]   Run one or more predefined groups"
  printf '%s\n' "  $0 list                  Show available jobs and groups"
  printf '%s\n' "  $0 help                  Show this help"
}

list_available_targets() {
  local job
  local group

  printf '%s\n' "Jobs:"
  for job in "${JOB_ORDER[@]}"; do
    printf '  %-17s %s\n' "$job" "$(job_description "$job")"
  done

  printf '\n%s\n' "Groups:"
  for group in all online-maintenance cold-maintenance metadata database; do
    printf '  %-20s %s\n' "$group" "$(group_description "$group")"
  done
}

run_job() {
  case "$1" in
  cold-backup) task_1_backup ;;
  db-backup) task_2_api_database_backup ;;
  analysis) task_3_plex_analysis ;;
  refresh-library) task_refresh_library ;;
  kometa) task_4_start_kometa ;;
  cleanup-bundles) task_5_cleanup_bundles ;;
  optimize-db) task_6_optimize_database ;;
  sync-secondary) task_7_sync_to_secondary ;;
  upgrade) paru -Sy --noconfirm plex-media-server-plexpass ;;
  *)
    log_error "Unknown job: $1"
    return 1
    ;;
  esac
}

run_jobs_in_order() {
  local requested_jobs=("$@")
  local -A selected_jobs=()
  local ordered_jobs=()
  local job

  for job in "${requested_jobs[@]}"; do
    selected_jobs["$job"]=1
  done

  for job in "${JOB_ORDER[@]}"; do
    if [[ -n "${selected_jobs[$job]+x}" ]]; then
      ordered_jobs+=("$job")
    fi
  done

  log "Selected jobs: $(join_by ', ' "${ordered_jobs[@]}")"

  for job in "${ordered_jobs[@]}"; do
    run_job "$job"
  done
}

################################################################################
# Main Maintenance Tasks
################################################################################

task_refresh_library() {
  local http_code

  log "Triggering library refresh..."
  http_code=$(plex_api_call "/library/sections/all/refresh" "GET")
  if [[ "$http_code" == "200" ]]; then
    log_success "Library refresh triggered"
  else
    log_error "Failed to trigger library refresh (HTTP $http_code)"
    return 1
  fi
}

task_1_backup() {
  log "==== TASK 1: Backup Database ===="

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

  # Start Plex Media Server
  log "Starting Plex Media Server..."
  systemctl start plexmediaserver

  wait_for_plex_ready 60 || exit 1
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

  wait_for_plex_background_tasks "database backup" 600 10 || return 1

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

task_3_plex_analysis() {
  log "==== TASK 3: Plex Analysis ===="

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

  task_refresh_library || return 1

  wait_for_plex_background_tasks "analysis and library refresh" 7200 15 || return 1
}

task_4_start_kometa() {
  log "==== TASK 4: Start Kometa Container ===="

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

task_5_cleanup_bundles() {
  log "==== TASK 5: Cleanup Old Bundles ===="

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

  wait_for_plex_background_tasks "bundle cleanup" 1800 15 || return 1
}

task_6_optimize_database() {
  log "==== TASK 6: Optimize Database ===="

  local http_code
  http_code=$(plex_api_call "/library/optimize" "PUT")

  if [[ "$http_code" == "200" ]]; then
    log_success "Database optimization started"
  else
    log_error "Failed to start database optimization (HTTP $http_code)"
    return 1
  fi

  wait_for_plex_background_tasks "database optimization" 3600 15 || return 1
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

  if ! wait_for_plex_ready 60; then
    log_error "Plex failed to restart on Primary after sync"
    return 1
  fi

  log_success "Plex Media Server restarted on Primary"

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
  local selected_jobs=()
  local expanded_jobs
  local target
  local job

  if [[ $# -eq 0 ]]; then
    selected_jobs=("${ALL_JOBS[@]}")
  else
    case "$1" in
    all)
      shift
      if [[ $# -gt 0 ]]; then
        log_error "The 'all' command does not accept additional arguments"
        print_usage
        exit 1
      fi
      selected_jobs=("${ALL_JOBS[@]}")
      ;;
    run)
      shift
      if [[ $# -eq 0 ]]; then
        log_error "No jobs specified"
        print_usage
        exit 1
      fi

      for target in "$@"; do
        if ! is_valid_job "$target"; then
          log_error "Unknown job: $target"
          list_available_targets
          exit 1
        fi
        selected_jobs+=("$target")
      done
      ;;
    group)
      shift
      if [[ $# -eq 0 ]]; then
        log_error "No groups specified"
        print_usage
        exit 1
      fi

      for target in "$@"; do
        if ! expanded_jobs=$(expand_group "$target"); then
          log_error "Unknown group: $target"
          list_available_targets
          exit 1
        fi

        while IFS= read -r job; do
          [[ -n "$job" ]] && selected_jobs+=("$job")
        done <<<"$expanded_jobs"
      done
      ;;
    list)
      list_available_targets
      return 0
      ;;
    help | -h | --help)
      print_usage
      return 0
      ;;
    *)
      log_error "Unknown command: $1"
      print_usage
      exit 1
      ;;
    esac
  fi

  log "========================================"
  log "Plex Maintenance Script Started"
  log "========================================"

  # Check requirements
  check_requirements "${selected_jobs[@]}"

  # Execute tasks in canonical order
  run_jobs_in_order "${selected_jobs[@]}"

  log "========================================"
  log_success "Maintenance run completed!"
  log "========================================"
}

# Run main function
main "$@"
