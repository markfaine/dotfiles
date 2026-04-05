#!/usr/bin/env bash
# smart_zfs_report_ntfy.sh
#
# Read S.M.A.R.T. data for disks used by ZFS pools and send a ntfy.sh
# notification if any potential issues are found.
#
# Requirements:
#  - zpool command (ZFS)
#  - smartctl (smartmontools)
#  - curl
#
# Configure via environment or edit the variables below:
#   NTFY_URL (default https://ntfy.sh)
#   NTFY_TOPIC (default zfs-smart)
#   NTFY_PRIORITY (default high) -- one of low, default, high, urgent
#   NTFY_TAGS (optional) -- comma-separated tags, e.g. "error,monitor"
#   NTFY_TITLE_PREFIX (default "ZFS SMART report")
#   NTFY_TOKEN (optional) -- if set, sent as "Authorization: Bearer <token>"
#   SMARTCTL_BIN (default /usr/sbin/smartctl)
#   ZPOOL_BIN (default /sbin/zpool)
#   SMARTCTL_OPTS (default empty) -- e.g. "-d sat"
#   TMPDIR (default /tmp)
#   DEBUG (default 1)
#   LOG_FILE (default /var/log/smart_zfs_report.log)
# -------------------------------------------------------

# --- Configuration (edit or override via environment) ---
NTFY_URL="${NTFY_URL:-http://192.168.1.100:8090}"
NTFY_TOPIC="${NTFY_TOPIC:-smart}"
NTFY_PRIORITY="${NTFY_PRIORITY:-high}"
NTFY_TAGS="${NTFY_TAGS:-}" # optional comma-separated tags, e.g. "error,monitor"
NTFY_TITLE_PREFIX="${NTFY_TITLE_PREFIX:-ZFS SMART report}"
NTFY_TOKEN="${NTFY_TOKEN:-}" # optional authentication token (Bearer)
SMARTCTL_BIN="${SMARTCTL_BIN:-/usr/sbin/smartctl}"
ZPOOL_BIN="${ZPOOL_BIN:-/sbin/zpool}"
SMARTCTL_OPTS="${SMARTCTL_OPTS:-}" # e.g. "-d sat"
TMPDIR="${TMPDIR:-/tmp}"
DEBUG=${DEBUG:-1}
LOG_FILE="${LOG_FILE:-/var/log/smart_zfs_report.log}"
# -------------------------------------------------------

# Ensure log file directory exists and redirect all stdout/stderr to log file and original stdout
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
  if [ "${DEBUG:-0}" -ne 0 ]; then
    printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >&2
  fi
}

# Global variable to track if a notification has been sent to prevent duplicates from ERR trap
_NTFY_SENT=0

# Tools checks
if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is required but not found." >&2
  exit 2
fi
if ! command -v "$SMARTCTL_BIN" >/dev/null 2>&1; then
  echo "ERROR: smartctl not found at $SMARTCTL_BIN. Install smartmontools or adjust SMARTCTL_BIN." >&2
  exit 2
fi
if ! command -v "$ZPOOL_BIN" >/dev/null 2>&1; then
  echo "ERROR: zpool not found at $ZPOOL_BIN. Is ZFS installed?" >&2
  exit 2
fi

TMPFILE="$(mktemp "${TMPDIR}/zfs-smart-report.XXXXXX")"
trap 'rm -f "$TMPFILE"' EXIT

# Get list of devices used by any ZFS pool (prefer full /dev paths)
get_zfs_devices() {
  local devs
  devs="$($ZPOOL_BIN status -P -v 2>/dev/null | grep -oE '/dev[^[:space:]]+' || true)"
  if [ -z "$devs" ]; then
    devs="$($ZPOOL_BIN status -v 2>/dev/null | awk '/ONLINE|DEGRADED|FAULTED|OFFLINE|REMOVED/ {print $1}' |
      egrep -v 'NAME|STATE|scan' || true)"
  fi
  printf '%s\n' "$devs" | sed '/^\s*$/d' | sort -u
}

get_attr_raw() {
  local name="$1"
  awk -v name="$name" 'BEGIN{IGNORECASE=1}
    {
      if ($1 ~ /^[0-9]+$/ && tolower($2) ~ tolower(name)) {
        print $NF
      }
    }' | head -n1
}

# Resolve a device path to the underlying whole-disk device suitable for smartctl.
# Tries, in order:
#  - readlink -f to resolve /dev/disk/by-id symlinks
#  - lsblk -no pkname to find parent disk of a partition
#  - fallback string manipulation for nvme (pN) and trailing-digit partitions
# Returns a path like /dev/sda or /dev/nvme0n1 (or the original path if it appears whole)
resolve_block_device() {
  local dev="$1"
  local real parent bname

  # If input isn't an absolute path, try prefixing /dev/
  if [ -z "$dev" ]; then
    return 1
  fi
  if [ "${dev#/dev/}" = "$dev" ] && [ -b "/dev/$dev" ]; then
    dev="/dev/$dev"
  fi

  # Resolve any symlink
  real="$(readlink -f "$dev" 2>/dev/null || true)"
  if [ -z "$real" ]; then
    # If readlink failed, fallback to the provided device
    real="$dev"
  fi

  # If it's already a whole device (block device and not a partition), return it
  if [ -b "$real" ]; then
    # try lsblk if available to determine if it's a partition with a parent
    if command -v lsblk >/dev/null 2>&1; then
      parent="$(lsblk -no pkname "$real" 2>/dev/null || true)"
      if [ -n "$parent" ]; then
        echo "/dev/$parent"
        return 0
      fi
    fi
  fi

  # Fallback heuristics (basename manipulations)
  bname="$(basename "$real")"

  # nvme style: nvme0n1p1 -> nvme0n1
  if printf '%s' "$bname" | grep -qE 'p[0-9]+$'; then
    echo "/dev/${bname%p*}"
    return 0
  fi

  # trailing digits: sda1 -> sda, vda2 -> vda
  if printf '%s' "$bname" | grep -qE '[0-9]+$'; then
    echo "/dev/$(printf '%s' "$bname" | sed 's/[0-9]\+$//')"
    return 0
  fi

  # otherwise return resolved name (may already be whole-disk)
  echo "$real"
  return 0
}

inspect_device() {
  local dev="$1"
  local resolved block_for_smart smart_info smart_health smart_attrs smart_selftest model serial firmware
  local has_issue=0

  # Try to resolve the device to a block device suitable for smartctl
  resolved="$(readlink -f "$dev" 2>/dev/null || true)"
  if [ -z "$resolved" ]; then
    # maybe zpool reported "sda" (no /dev/) - prefix /dev/
    if [ -b "/dev/$dev" ]; then
      resolved="/dev/$dev"
    else
      resolved="$dev"
    fi
  fi

  block_for_smart="$(resolve_block_device "$resolved")"

  {
    printf 'Device reported by zpool: %s\n' "$dev"
    if [ "$resolved" != "$block_for_smart" ]; then
      printf '  Resolved block device for smartctl: %s\n' "$block_for_smart"
    else
      printf '  Using device: %s\n' "$block_for_smart"
    fi

    # Run smartctl on the resolved whole-disk device
    if smart_info="$(sudo "$SMARTCTL_BIN" "$SMARTCTL_OPTS" -i "$block_for_smart" 2>&1)"; then
      model="$(printf '%s\n' "$smart_info" | awk -F: '/Model Family|Device Model|Model/ {print substr($0, index($0,$2)+1)}' | sed 's/^[[:space:]]*//g' | head -n1 || true)"
      serial="$(printf '%s\n' "$smart_info" | awk -F: '/Serial Number/ {print substr($0, index($0,$2)+1)}' | sed 's/^[[:space:]]*//g' | head -n1 || true)"
      firmware="$(printf '%s\n' "$smart_info" | awk -F: '/Firmware Version/ {print substr($0, index($0,$2)+1)}' | sed 's/^[[:space:]]*//g' | head -n1 || true)"
      [ -n "$model" ] && printf '  Model: %s\n' "$model"
      [ -n "$serial" ] && printf '  Serial: %s\n' "$serial"
      [ -n "$firmware" ] && printf '  Firmware: %s\n' "$firmware"
    else
      printf '  ERROR: smartctl -i failed for %s\n' "$block_for_smart"
      has_issue=1
    fi

    if smart_health="$(sudo "$SMARTCTL_BIN" "$SMARTCTL_OPTS" -H "$block_for_smart" 2>&1)"; then
      printf '  SMART Health: %s\n' "$(printf '%s\n' "$smart_health" | sed -n '1,3p' | tr '\n' ' ')"
      if printf '%s\n' "$smart_health" | grep -iE 'failed|failing|pre-fail|degree of failure' >/dev/null 2>&1; then
        has_issue=1
      fi
    else
      printf '  WARNING: smartctl -H failed for %s\n' "$block_for_smart"
      has_issue=1
    fi

    smart_attrs="$(sudo "$SMARTCTL_BIN" "$SMARTCTL_OPTS" -A "$block_for_smart" 2>&1 || true)"
    printf '  Key Attributes:\n'
    local attrs_to_check=(Reallocated_Sector_Ct Reallocated_Event_Count Current_Pending_Sector Offline_Uncorrectable UDMA_CRC_Error_Count)
    for a in "${attrs_to_check[@]}"; do
      local val
      val="$(printf '%s\n' "$smart_attrs" | get_attr_raw "$a" || true)"
      if [ -n "$val" ]; then
        printf '    %s: %s\n' "$a" "$val"
        if printf '%s\n' "$val" | grep -E '^[0-9]+' >/dev/null 2>&1; then
          if [ "$(printf '%s\n' "$val" | awk '{print ($1+0)}')" -gt 0 ]; then
            has_issue=1
          fi
        fi
      fi
    done

    smart_selftest="$(sudo "$SMARTCTL_BIN" "$SMARTCTL_OPTS" -l selftest "$block_for_smart" 2>&1 || true)"
    if printf '%s\n' "$smart_selftest" | grep -iE 'failed|read failure|aborted|interrupted|Completed: read failure' >/dev/null 2>&1; then
      printf '  Self-test: one or more recent self-tests indicate errors\n'
      printf '    Self-test log (excerpt):\n'
      printf '%s\n' "$smart_selftest" | sed -n '1,20p' | sed 's/^/      /'
      has_issue=1
    else
      if [ -n "$smart_selftest" ]; then
        printf '  Self-test summary:\n'
        printf '%s\n' "$smart_selftest" | sed -n '1,6p' | sed 's/^/    /'
      fi
    fi

    smart_errlog="$(sudo "$SMARTCTL_BIN" "$SMARTCTL_OPTS" -l error "$block_for_smart" 2>&1 || true)"
    if printf '%s\n' "$smart_errlog" | grep -iE 'Error|ATA Error' >/dev/null 2>&1; then
      printf '  Error log: errors found (excerpt):\n'
      printf '%s\n' "$smart_errlog" | sed -n '1,12p' | sed 's/^/    /'
      has_issue=1
    fi

    printf '\n'
  } >>"$TMPFILE"

  return $has_issue
}

# send_ntfy function:
# $1: subject
# $2: body (either raw text or path to a file)
# $3: "file" if $2 is a file path, "text" (or empty) if $2 is raw text
send_ntfy() {
  local subject="$1"
  local body="$2"
  local body_type="$3" # "file" or "text"

  local url="${NTFY_URL%/}/$NTFY_TOPIC"
  local -a headers
  headers+=("-H" "Title: $subject")
  headers+=("-H" "Priority: $NTFY_PRIORITY")
  if [ -n "${NTFY_TAGS}" ]; then
    headers+=("-H" "Tags: ${NTFY_TAGS}")
  fi
  if [ -n "${NTFY_TOKEN}" ]; then
    headers+=("-H" "Authorization: Bearer ${NTFY_TOKEN}")
  fi

  log "Attempting to send ntfy notification to ${url} (priority=${NTFY_PRIORITY})"

  local curl_output
  if [ "$body_type" = "file" ]; then
    curl_output=$(curl -sfS "${headers[@]}" --data-binary @"$body" "$url" 2>&1)
  else
    curl_output=$(curl -sfS "${headers[@]}" --data-binary "$body" "$url" 2>&1)
  fi

  if [ $? -eq 0 ]; then
    log "ntfy sent successfully."
    _NTFY_SENT=1 # Mark that a notification has been sent
    return 0
  else
    log "ERROR: Failed to post notification to $url. Curl output: $curl_output"
    _NTFY_SENT=0 # Keep it 0 if it fails
    return 1
  fi
}

# Main
devices="$(get_zfs_devices)"
if [ -z "$devices" ]; then
  log "No ZFS devices found via zpool status. Exiting."
  # Send a notification for no devices found, consider it a success if nothing to check
  subject="$NTFY_TITLE_PREFIX: No ZFS devices found on $(hostname -f 2>/dev/null || hostname)"
  body="No ZFS pools or devices were detected by 'zpool status'. No SMART checks performed."
  send_ntfy "$subject" "$body" "text" || log "ERROR: Failed to send ntfy notification for no ZFS devices."
  exit 0
fi

printf 'ZFS SMART scan report\n' >"$TMPFILE"
printf 'Generated: %s (UTC)\n\n' "$(date -u +'%Y-%m-%d %H:%M:%S')" >>"$TMPFILE"

issues=0
while IFS= read -r dev; do
  [ -z "$dev" ] && continue
  log "Inspecting: $dev"
  if inspect_device "$dev"; then
    issues=$((issues + 1))
  fi
done <<<"$devices"

if [ "$issues" -gt 0 ]; then
  subject="$NTFY_TITLE_PREFIX: $issues drive(s) with potential issues on $(hostname -f 2>/dev/null || hostname)"
  send_ntfy "$subject" "$TMPFILE" "file" || log "ERROR: Failed to send ntfy notification for issues found."
else
  subject="$NTFY_TITLE_PREFIX: OK on $(hostname -f 2>/dev/null || hostname)"
  body="All ZFS drives passed SMART health checks. No issues found."
  send_ntfy "$subject" "$body" "text" || log "ERROR: Failed to send ntfy notification for successful scan."
fi

# Exit non-zero if issues found (useful for automation)
if [ "$issues" -gt 0 ]; then
  exit 1
else
  exit 0
fi
