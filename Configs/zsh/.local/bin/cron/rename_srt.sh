#!/usr/bin/env bash
# rename_srt.sh
# Efficiently finds all .srt files and renames them.
# - If a single video file exists in the directory, the subtitle is renamed to match the video filename.
# - This version is optimized to reduce redundant operations and process forks.
#
# Usage:
#   ./rename_srt.sh [path_to_videos]

set -euo pipefail

ROOT="${1:-/volume1/video}"

# Enable extended globbing for '!*' pattern matching. This is safe to set within the script.
shopt -s extglob

# Process files directory by directory for efficiency.
# The outer find/sort/while loop iterates over unique directories containing .srt files.
# Using -print0, -z, and -d '' makes this safe for filenames with spaces/newlines.
find "$ROOT" -type f -name "*.srt" -printf '%h\0' | sort -zu | while IFS= read -r -d '' dir;
 do
  # Find video files in the current directory just once.
  mapfile -t vids < <(find "$dir" -maxdepth 1 -type f \( -iname '*.mkv' -o -iname '*.mp4' \) -printf '%f\n')

  video_prefix=""
  if [ ${#vids[@]} -eq 1 ]; then
    # Exactly one video file found, use its name as the base for subtitles.
    videofile="${vids[0]}"
    video_prefix="${videofile%.*}"
  fi

  # The inner find/while loop iterates over .srt files within the current directory.
  find "$dir" -maxdepth 1 -type f -name "*.srt" -print0 | while IFS= read -r -d '' sub_path;
   do
    sub_file="${sub_path##*/}"

    # Extract language suffix, e.g., ".en.srt"
    name_no_ext="${sub_file%.srt}"
    lang="${name_no_ext##*.}"
    suffix=".${lang}.srt"

    # Get the current prefix, removing any leading '!' using extglob.
    name_no_bang="${sub_file#+(!)}"
    cur_prefix="${name_no_bang%${suffix}}"

    # Determine the new prefix. Use video prefix if available, otherwise keep current.
    new_prefix="$cur_prefix"
    if [ -n "$video_prefix" ]; then
      new_prefix="$video_prefix"
    fi

    # Construct the new filename.
    new_base="${new_prefix}${suffix}"

    # Rename if the name has changed.
    if [ "$new_base" != "$sub_file" ]; then
      dst_path="$dir/$new_base"
      # Use -f to overwrite, matching original script behavior.
      mv -f -- "$sub_path" "$dst_path"
      #printf "Renamed: %s -> %s\n" "$sub_path" "$dst_path"
    fi
  done
done

#echo "Subtitle renaming complete."
