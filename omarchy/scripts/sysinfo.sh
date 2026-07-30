#!/bin/bash

PREV_TOTAL=0; PREV_IDLE=0
while IFS=' ' read -r label rest; do
  if [[ "$label" == "cpu" ]]; then
    set -- $rest
    PREV_IDLE=$(( $4 + $5 ))
    PREV_TOTAL=$(( $1 + $2 + $3 + $4 + $5 + $6 + $7 + $8 ))
    break
  fi
done < /proc/stat

sleep 0.1

CUR_TOTAL=0; CUR_IDLE=0
while IFS=' ' read -r label rest; do
  if [[ "$label" == "cpu" ]]; then
    set -- $rest
    CUR_IDLE=$(( $4 + $5 ))
    CUR_TOTAL=$(( $1 + $2 + $3 + $4 + $5 + $6 + $7 + $8 ))
    break
  fi
done < /proc/stat

DIFF_IDLE=$(( CUR_IDLE - PREV_IDLE ))
DIFF_TOTAL=$(( CUR_TOTAL - PREV_TOTAL ))
CPU=$(( (DIFF_TOTAL - DIFF_IDLE) * 100 / DIFF_TOTAL ))

MEM_TOTAL=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
MEM_AVAIL=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
MEM_FREE=$(awk '/^MemFree:/ {print $2}' /proc/meminfo)
SWAP_TOTAL=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
SWAP_FREE=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)
MEM_PCT=$(( (MEM_TOTAL - MEM_AVAIL) * 100 / MEM_TOTAL ))
SWAP_PCT=0
[[ "$SWAP_TOTAL" -gt 0 ]] && SWAP_PCT=$(( (SWAP_TOTAL - SWAP_FREE) * 100 / SWAP_TOTAL ))

read DISK_TOTAL DISK_USED DISK_PCT < <(df / --output=size,used,pcent 2>/dev/null | tail -1 || df / | awk 'NR==2 {print $2,$3,substr($5,1,length($5)-1)}')
DISK_PCT=${DISK_PCT%\%}

PS_JSON="["
FIRST=true
while IFS='|' read -r name rss; do
  $FIRST || PS_JSON+=","
  FIRST=false
  name="${name//\\/\\\\}"
  name="${name//\"/\\\"}"
  PS_JSON+="{\"name\":\"$name\",\"rss\":$((rss))}"
done < <(ps aux --sort=-%mem 2>/dev/null | awk 'NR>1 && NR<10 {n=$11; sub(/.*\//,"",n); printf "%s|%s\n", substr(n,1,15), $6}')
PS_JSON+="]"

UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")

cat <<EOF
{"cpu":$CPU,"memPercent":$MEM_PCT,"memTotal":$MEM_TOTAL,"memAvail":$MEM_AVAIL,"memFree":$MEM_FREE,"swapPercent":$SWAP_PCT,"swapTotal":$SWAP_TOTAL,"swapFree":$SWAP_FREE,"diskPercent":$DISK_PCT,"diskUsed":$DISK_USED,"diskTotal":$DISK_TOTAL,"processes":$PS_JSON,"uptime":"$UPTIME"}
EOF
