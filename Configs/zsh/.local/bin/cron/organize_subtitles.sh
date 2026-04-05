#!/bin/bash

# The root directory for television shows
TV_ROOT="/volume1/video/television"

# Find all "Season X" directories
mapfile -t seasons < <(find "$TV_ROOT" -type d -name "Season *")
for season_dir in "${seasons[@]}"; do
  # Create the "Subtitles" directory if it doesn't exist
  subtitles_dir="$season_dir/Subtitles"
  mkdir -p "$subtitles_dir"

  # Find all .srt files in the season directory (but not in subdirectories)
  # and move them to the "Subtitles" directory.
  mapfile -t subs < <(find "$season_dir" -maxdepth 2 -type f -name "*.srt" -not -path "*/Subtitles/*")
  for srt_file in "${subs[@]}"; do
    mv "$srt_file" "$subtitles_dir/"
    #    echo "Moved $(basename "$srt_file") to $subtitles_dir"
  done
done
#echo "Subtitle organization complete."
