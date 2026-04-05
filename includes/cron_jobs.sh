#!/usr/bin/env bash
set -euo pipefail

# --- Detection ---
IS_SWARM_MANAGER=$(docker info --format '{{.Swarm.ControlAvailable}}' 2>/dev/null || echo "false")
HAS_ZFS=$(command -v zpool >/dev/null && zpool status >/dev/null 2>&1 && echo "true" || echo "false")

# Check for Tdarr by looking for the JobReports directory mentioned in its script
IS_TDARR_HOST=$([ -d "/volume1/containers/swarms/arr/tdarr/server/Tdarr/DB2/JobReports" ] && echo "true" || echo "false")

# Check for NFS mount
HAS_NFS_MOUNT=$(mount | grep volume1 | grep -q nfs && echo "true" || echo "false")

echo "--- Node Detection ---"
echo "Swarm Manager: $IS_SWARM_MANAGER"
echo "ZFS Host:      $HAS_ZFS"
echo "Tdarr Host:    $IS_TDARR_HOST"
echo "NFS Mount:     $HAS_NFS_MOUNT"
echo "----------------------"

add_cron() {
  local schedule="$1"
  local cmd="$2"
  local comment="$3"
  local tag="[MGMT] $comment"

  echo "Adding cron job: $comment ($schedule)"

  # Filter out lines containing the command OR the specific tag to avoid duplicates/stale comments
  # We use temporary files to be safer with pipes and crontab
  local tmp_cron
  tmp_cron=$(mktemp)
  sudo crontab -l 2>/dev/null | grep -vF "$cmd" | grep -vF "$tag" >"$tmp_cron" || true

  printf "# %s\n" "$tag" >>"$tmp_cron"
  printf "%s %s\n" "$schedule" "$cmd" >>"$tmp_cron"

  sudo crontab "$tmp_cron"
  rm "$tmp_cron"
}

# Backup database
if docker ps --filter=name=mariadb --format '{{.Names}}' | grep -q mariadb; then
  add_cron "0 */1 * * *" "$HOME/.local/bin/cron/backup_database.sh" "Backup Mariadb database"
fi

# Check system runs on all hosts
add_cron "*/5 * * * *" "$HOME/.local/bin/cron/check_system.sh" "Check System"

# NFS Hosts Only
if [ "$HAS_NFS_MOUNT" = "true" ]; then
  add_cron "*/5 * * * *" "$HOME/.local/bin/cron/check_nfs.sh" "Check NFS writability"
fi

# ZFS Hosts Only
if [ "$HAS_ZFS" = "true" ]; then
  add_cron "*/10 * * * *" "$HOME/.local/bin/cron/check_zfs.sh" "Check ZFS pool health"

  # Scrub intensity management
  add_cron "24 0 * * 0" "echo 4 > /sys/module/zfs/parameters/zfs_vdev_scrub_max_active" "ZFS Night Mode (High Scrub)"
  add_cron "0 8 * * *" "echo 1 > /sys/module/zfs/parameters/zfs_vdev_scrub_max_active" "ZFS Day Mode (Low Scrub)"
fi

# Swarm Manager Nodes
if [ "$IS_SWARM_MANAGER" = "true" ]; then
  add_cron "1 */1 * * *" "$HOME/.local/bin/cron/rename_srt.sh &>/dev/null" "Rename subtitles to match video"
  add_cron "5 */1 * * *" "$HOME/.local/bin/cron/organize_subtitles.sh &>/dev/null" "Organize subtitles into sub-folders"
  add_cron "0 3 * * *" "$HOME/.local/bin/cron/smart_zfs_report.sh 2>&1" "ZFS SMART health report"
  add_cron "0 0 * * *" "$HOME/.local/bin/cron/update_docker_images.sh &>/dev/null" "Update Docker containers"
  add_cron "0 4 * * *" "$HOME/.local/bin/cron/plex-maintenance.sh &>/dev/null" "Plex maintenance and backup"
  add_cron "0 */6 * * *" "$HOME/.local/bin/cron/plex-tasks.sh &>/dev/null" "Plex Routine Tasks"
else
  # Non-Swarm Manager Nodes
  add_cron "0 */12 * * *" "$HOME/.local/bin/cron/arr_manager.sh &>/dev/null" "Arr Apps Routine Tasks"
fi

# 6. Tdarr Host
if [ "$IS_TDARR_HOST" = "true" ]; then
  add_cron "0 */6 * * *" "$HOME/.local/bin/cron/tdarr_avg_transcode.sh 6 >/dev/null 2>&1" "Tdarr average transcode stats"
fi

echo "Installation complete."
