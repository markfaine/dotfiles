#!/usr/bin/env bash
set -euo pipefail

# Config (override via env or first arg)
LOG_DIR="${LOG_DIR:-/home/mfaine}"
JR_DIR="${JR_DIR:-/volume1/containers/swarms/arr/tdarr/server/Tdarr/DB2/JobReports}"
HOURS_ARG="${1:-}" 
HOURS="${HOURS_ARG:-${HOURS:-12}}"
NTFY_BASE="${NTFY_BASE:-https://ntfy.local.markfaine.net}"
NTFY_TOPIC="${NTFY_TOPIC:-tdarr}"
NTFY_TITLE="${NTFY_TITLE:-Tdarr avg transcode}"
INSECURE="${INSECURE:-false}"

cutoff_epoch=$(date -d "$HOURS hours ago" +%s)
tv_sum=0; tv_n=0; mov_sum=0; mov_n=0
tv_values=()
mov_values=()


# Prefer JobReports
if [ -d "$JR_DIR" ]; then
  mmin=$((HOURS*60))
  while IFS= read -r -d '' jf; do
    ts=$(grep -m1 -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$jf" || true)
    [ -z "$ts" ] && continue
    epoch=$(date -d "$ts" +%s 2>/dev/null || echo 0)
    [ "$epoch" -lt "$cutoff_epoch" ] && continue

    type="UNKNOWN"
    if grep -qi '/television' "$jf"; then type="TV"; fi
    if grep -qi '/movies' "$jf"; then type="MOVIE"; fi

    secs=""
    secs=$(grep -Eo '"?duration"?[[:space:]]*:[[:space:]]*[0-9]+(\.[0-9]+)?' "$jf" | head -n1 | grep -Eo '[0-9]+(\.[0-9]+)?' || true)
    if [ -z "$secs" ]; then
      durv=$(grep -Eo 'Duration"[[:space:]]*[:"]*[0-9]{2}:[0-9]{2}:[0-9]{2}' "$jf" | head -n1 | sed -E 's/.*([0-9]{2}:[0-9]{2}:[0-9]{2}).*/\1/' || true)
      if [ -n "$durv" ]; then
        IFS=':' read -r h m s <<< "$durv"
        secs=$(awk -v hh="$h" -v mm="$m" -v ss="$s" 'BEGIN{print hh*3600 + mm*60 + ss}')
      fi
    fi
    if [ -z "$secs" ]; then
      ms=$(grep -Eo '[0-9]{1,}[[:space:]]*ms' "$jf" | head -n1 | grep -Eo '[0-9]+' || true)
      if [ -n "$ms" ]; then secs=$(awk -v m="$ms" 'BEGIN{print m/1000}'); fi
    fi
    if [ -z "$secs" ]; then
      s1=$(grep -Eo 'Finished in [0-9]+(\.[0-9]+)?s' "$jf" | head -n1 | grep -Eo '[0-9]+(\.[0-9]+)?' || true)
      if [ -n "$s1" ]; then secs="$s1"; fi
    fi
    if [ -z "$secs" ]; then
      secs=$(grep -Eo '[0-9]+(\.[0-9]+)?s' "$jf" | head -n1 | grep -Eo '[0-9]+(\.[0-9]+)?' || true)
    fi

    if [ -n "$secs" ] && [ "$type" != "UNKNOWN" ]; then
      if [ "$type" = "TV" ]; then tv_sum=$(awk -v a="$tv_sum" -v b="$secs" 'BEGIN{printf "%.6f", a+b}'); tv_n=$((tv_n+1)); tv_values+=("$secs"); fi
      if [ "$type" = "MOVIE" ]; then mov_sum=$(awk -v a="$mov_sum" -v b="$secs" 'BEGIN{printf "%.6f", a+b}'); mov_n=$((mov_n+1)); mov_values+=("$secs"); fi
    fi

  done < <(find "$JR_DIR" -type f -name '*transcode*.txt' -mmin -"$mmin" -print0 2>/dev/null)
fi

# Fallback to log parsing if nothing from JobReports
if [ "$tv_n" -eq 0 ] && [ "$mov_n" -eq 0 ]; then
  mmin=$((HOURS*60))
  while IFS= read -r -d '' lf; do
    while IFS= read -r line; do
      ts=$(echo "$line" | grep -m1 -Eo '^[[]?[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' || true)
      [ -z "$ts" ] && continue
      epoch=$(date -d "$ts" +%s 2>/dev/null || echo 0)
      [ "$epoch" -lt "$cutoff_epoch" ] && continue
      s=""
      s=$(echo "$line" | grep -Eo '[0-9]+ms' | head -n1 | grep -Eo '[0-9]+' || true)
      if [ -n "$s" ]; then s=$(awk -v x="$s" 'BEGIN{print x/1000}'); fi
      if [ -z "$s" ]; then s=$(echo "$line" | grep -Eo '[0-9]+(\.[0-9]+)?s' | head -n1 | grep -Eo '[0-9]+(\.[0-9]+)?' || true); fi
      if [ -n "$s" ]; then tv_sum=$(awk -v a="$tv_sum" -v b="$s" 'BEGIN{printf "%.6f", a+b}'); tv_n=$((tv_n+1)); tv_values+=("$s"); fi
    done < "$lf"
  done < <(find "$LOG_DIR" -type f -name 'Tdarr_*_Log.txt*' -mmin -"$mmin" -print0 2>/dev/null)
fi

# compute averages and medians
# helper to format seconds to H:MM:SS
secs_to_hms(){
  local T=$1
  local H=$((T/3600))
  local M=$(((T%3600)/60))
  local S=$((T%60))
  printf "%d:%02d:%02d" "$H" "$M" "$S"
}

median(){
  # compute median of numeric arguments
  local arr=($(printf "%s\n" "$@" | awk '{print $1}' | sort -n))
  local n=${#arr[@]}
  if [ "$n" -eq 0 ]; then echo ""; return; fi
  if (( n % 2 == 1 )); then
    echo "${arr[$((n/2))]}"
  else
    a=${arr[$((n/2-1))]}; b=${arr[$((n/2))]}
    awk -v x="$a" -v y="$b" 'BEGIN{printf "%.6f", (x+y)/2}'
  fi
}

if [ "$tv_n" -gt 0 ]; then avg_tv_f=$(awk -v s="$tv_sum" -v n="$tv_n" 'BEGIN{printf "%.0f", s/n}'); avg_tv=$(secs_to_hms "$avg_tv_f"); tv_median_f=$(median "${tv_values[@]:-}"); tv_median=$( [ -n "$tv_median_f" ] && secs_to_hms "$(printf "%.0f" "$tv_median_f")" || echo ""); else avg_tv="NA"; fi
if [ "$mov_n" -gt 0 ]; then avg_mov_f=$(awk -v s="$mov_sum" -v n="$mov_n" 'BEGIN{printf "%.0f", s/n}'); avg_mov=$(secs_to_hms "$avg_mov_f"); mov_median_f=$(median "${mov_values[@]:-}"); mov_median=$( [ -n "$mov_median_f" ] && secs_to_hms "$(printf "%.0f" "$mov_median_f")" || echo ""); else avg_mov="NA"; fi

if [ "$tv_n" -eq 0 ] && [ "$mov_n" -eq 0 ]; then
  data="No transcode durations found in the last $HOURS hours."
else
  if [ "$mov_n" -eq 0 ] && [ "$tv_n" -gt 0 ] && [ -z "$(find "$JR_DIR" -type f -name '*.txt' 2>/dev/null)" ]; then
    data="Tdarr average transcode (last $HOURS h): Overall: ${avg_tv} (n=${tv_n})"
  else
    tv_part="TV: none"; mov_part="Movies: none"
    [ "$tv_n" -gt 0 ] && tv_part="TV: ${avg_tv} (n=${tv_n})"
    [ "$mov_n" -gt 0 ] && mov_part="Movies: ${avg_mov} (n=${mov_n})"
    data="Tdarr average transcode (last $HOURS h): $tv_part, $mov_part"
  fi
fi

echo "$data"

# append CSV: timestamp,window_hours,tv_avg_s,tv_count,tv_median_s,mov_avg_s,mov_count,mov_median_s,tv_avg_h,tv_median_h,mov_avg_h,mov_median_h
CSV_FILE="${CSV_FILE:-$LOG_DIR/tdarr_avg_transcode.csv}"
# write header if missing or header is old format
if [ ! -f "$CSV_FILE" ]; then
  echo "timestamp,window_hours,tv_avg_s,tv_count,tv_median_s,mov_avg_s,mov_count,mov_median_s,tv_avg_h,tv_median_h,mov_avg_h,mov_median_h" > "$CSV_FILE" || true
else
  head -n1 "$CSV_FILE" | grep -q "tv_median_h" || sed -i '1s/.*/timestamp,window_hours,tv_avg_s,tv_count,tv_median_s,mov_avg_s,mov_count,mov_median_s,tv_avg_h,tv_median_h,mov_avg_h,mov_median_h/' "$CSV_FILE" || true
fi
# raw seconds values saved for analysis; fallback overall uses tv_avg_f as overall
tv_avg_raw=""
mov_avg_raw=""
[ -n "${avg_tv_f:-}" ] && tv_avg_raw="${avg_tv_f}"
[ -n "${avg_mov_f:-}" ] && mov_avg_raw="${avg_mov_f}"
if [ -z "$tv_avg_raw" ]; then tv_avg_raw=""; fi
if [ -z "$mov_avg_raw" ]; then mov_avg_raw=""; fi
# medians (seconds) -> convert to H:MM:SS for CSV
[ -n "${tv_median_f:-}" ] || tv_median_f=""
[ -n "${mov_median_f:-}" ] || mov_median_f=""
# convert median/raw seconds to integer seconds for CSV formatting
tv_median_csv=""
mov_median_csv=""
if [ -n "$tv_median_f" ]; then tv_median_csv=$(secs_to_hms "$(printf "%.0f" "$tv_median_f")"); fi
if [ -n "$mov_median_f" ]; then mov_median_csv=$(secs_to_hms "$(printf "%.0f" "$mov_median_f")"); fi
# avg H:MM:SS
[ -n "${avg_tv_f:-}" ] && tv_avg_h=$(secs_to_hms "$(printf "%.0f" "$avg_tv_f")") || tv_avg_h=""
[ -n "${avg_mov_f:-}" ] && mov_avg_h=$(secs_to_hms "$(printf "%.0f" "$avg_mov_f")") || mov_avg_h=""

printf "%s,%s,%s,%d,%s,%s,%d,%s,%s,%s,%s,%s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$HOURS" "$tv_avg_raw" "$tv_n" "$tv_median_f" "$mov_avg_raw" "$mov_n" "$mov_median_f" "$tv_avg_h" "$tv_median_csv" "$mov_avg_h" "$mov_median_csv" >> "$CSV_FILE" || true

# send to ntfy
curl_opts=(-sS -X POST -H "Title: $NTFY_TITLE" -d "$data")
[ "$INSECURE" = "true" ] && curl_opts+=(-k)
curl "${curl_opts[@]}" "$NTFY_BASE/$NTFY_TOPIC" || echo "ntfy send failed" >&2
