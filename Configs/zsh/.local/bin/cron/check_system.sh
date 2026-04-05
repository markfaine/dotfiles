#!/usr/bin/env bash

HOSTNAME=$(hostname)
PUSH_URL="http://192.168.1.3:3001/api/push"
TOKEN="qjNyA7ca6dvwwqh945RY12vUTDI7hyVT"
if [[ "$HOSTNAME" == "worker1" ]]; then
  TOKEN="1PIwRn93ZV3sgXjPc8aLBMJUzbM930VT"
fi
PUSH_URL="$PUSH_URL/$TOKEN"
POOL=volume1

if [[ "$HOSTNAME" == "worker1" ]]; then
  SCRUB_STATUS="None"
else
  SCRUB_STATUS=$(zpool status "$POOL" | grep -q "scrub in progress" && echo "SCRUBBING" || echo "IDLE")
fi

# 1. CPU Usage (%)
CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
#echo "CPU: $CPU%"

# 2. RAM Usage (%)
RAM=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
#echo "RAM: $RAM%"

# 3. Load Average (1 min)
LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)

# 4. I/O Wait (%)
IOWAIT=$(iostat -c 1 2 | awk '/avg-cpu/ {getline; print $4}' | tail -n 1)

# 5. Nvidia GPU Usage & Temp
if command -v nvidia-smi &>/dev/null; then
  GPU_DATA=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
  GPU_UTIL=$(echo "$GPU_DATA" | cut -d',' -f1 | xargs)
  GPU_TEMP=$(echo "$GPU_DATA" | cut -d',' -f2 | xargs)
else
  GPU_UTIL="N/A"
  GPU_TEMP="N/A"
fi

# THRESHOLDS: Stop pushing if critical
if (($(echo "$RAM > 95" | bc -l))) || (($(echo "$CPU > 95" | bc -l))); then
  logger "System Health Alert on $HOSTNAME: CPU:$CPU RAM:$RAM"
else
  # SUCCESS: Include Hostname in the message
  MSG="[${HOSTNAME}]_CPU:${CPU}%_RAM:${RAM}%_Load:${LOAD}_IO:${IOWAIT}%_GPU:${GPU_UTIL}%_Temp:${GPU_TEMP}C_SCRUB_STATUS:${SCRUB_STATUS}"

  # Push to Kuma (using CPU as the graph 'ping' value)
  curl -s -G "${PUSH_URL}" \
    --data-urlencode "status=up" \
    --data-urlencode "msg=${MSG}" \
    --data-urlencode "ping=${CPU}" \
    &>/dev/null

fi
