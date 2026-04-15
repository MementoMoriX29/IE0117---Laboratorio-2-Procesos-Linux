#!/bin/bash

LOG="/var/log/monitor_sistema.log"
INTERVALO=5

echo "TIMESTAMP PID NOMBRE CPU% MEM%" >> "$LOG"

while true; do
    TS=$(date "+%Y-%m-%d %H:%M:%S")
    ps -eo pid,comm,pcpu,pmem | tail -n +2 | sort -k3 -rn | head -5 | while read -r PID NOMBRE CPU MEM; do
        echo "$TS $PID $NOMBRE $CPU $MEM" >> "$LOG"
    done
    sleep "$INTERVALO"
done

