#!/bin/bash

################################################################################
# Plex Tasks
# Routine tasks performed in support of Plex
################################################################################

set -euo pipefail

# Configuration
PLEX_SERVER="127.0.0.1"
PLEX_PORT="32400"
PLEX_TOKEN="sVD35zGYmxc4b5NgDb9g" # REQUIRED: Set your Plex token here or via environment variable
PLEX_ROOT_DIR="/var/lib/plex/Plex Media Server"
PLEX_SOURCE_DIR="$PLEX_ROOT_DIR"
LOG_FILE="/var/log/plex-maintenance.log"

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
  local required_commands=("curl" "rsync" "systemctl" "docker")
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

################################################################################
# Main Routine Tasks
################################################################################

task_refresh_library() {
  log "==== TASK 2: Plex Refresh Library ===="

  # Trigger library scan for movies
  http_code=$(plex_api_call "/library/sections/all/refresh" "GET")
  if [[ "$http_code" == "200" ]]; then
    log_success "Library refresh triggered"
  else
    log_error "Failed to trigger library refresh (HTTP $http_code)"
    return 1
  fi
}

################################################################################
# Main Script Execution
################################################################################

main() {
  log "========================================"
  log "Plex Routine Script Started"
  log "========================================"

  # Check requirements
  check_requirements

  # Execute tasks in order
  task_refresh_library

  log "========================================"
  log_success "All maintenance tasks completed!"
  log "========================================"
}

# Run main function
main "$@"
