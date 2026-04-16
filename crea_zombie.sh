#!/bin/bash
# El padre crea un hijo y nunca llama a wait()
bash -c 'exit 0' & # hijo termina de inmediato
HIJO=$!
echo "Hijo PID: $HIJO revisando en 5 segundos..."
sleep 5
# En este punto el hijo puede estar en estado Z
ps -o pid,ppid,stat,comm -p $HIJO
echo "Padre dormido. Para ver el zombie: ps aux | grep Z"
sleep 60
