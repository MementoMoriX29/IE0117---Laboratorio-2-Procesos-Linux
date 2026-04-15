#!/bin/bash
# El siguiente script es sobre el monitoreo de procesos con graficacion

# Programacion Bajo Plataformas Abiertas

# R1. Recepcion de argumentos

if [ $# -lt 1 ]; then
   echo "Uso: $0 \"<comando>\" [intervalo_segundos]"
   echo "Ejemplo: $0 \"stress --cpu 2 --timeout 30\" 1"
   exit 1
fi

COMANDO="$1"
INTERVALO="${2:-2}"

# R2. Ejecutar el proceso en segundo plano
bash -c "$COMANDO" &
PID=$!

LOG="monitor_${PID}.log"

echo "Proceso lanzado: '$COMANDO' con PID $PID"
echo "Intervalo: ${INTERVALO}s"
echo "Log: $LOG"

# R3. Encabezado del Log
echo "TIMESTAMP CPU% MEM% MEM_RSS_KB" > "$LOG"

# R5. Función para graficar
graficar() {
    TMPDAT="monitor_${PID}_tmp.dat"
    # Asegurar que el archivo temporal esté limpio
    > "$TMPDAT"
    
    # Leer el log y convertir timestamp a segundos relativos
    PRIMERO=1
    while read -r fecha hora cpu mem rss; do
        # Saltar la línea de encabezado
        [[ "$fecha" == "TIMESTAMP" ]] && continue
        
        TS="$fecha $hora"
        EPOCH=$(date -d "$TS" +%s)
        
        if [ "$PRIMERO" -eq 1 ]; then
            INICIO=$EPOCH
            PRIMERO=0
        fi
        
        SEG=$((EPOCH - INICIO))
        echo "$SEG $cpu $rss" >> "$TMPDAT"
    done < "$LOG"

    NOMBRE=$(echo "$COMANDO" | awk '{print $1}')

    # Generar gráfico con Gnuplot
    gnuplot << EOF
set terminal png
set output "monitor_${PID}.png"
set title "Monitor: $NOMBRE (PID $PID)"
set xlabel "Tiempo (s)"
set ylabel "CPU (%)"
set y2label "Memoria RSS (KB)"
set ytics nomirror
set y2tics
set grid
plot "$TMPDAT" using 1:2 with lines title "CPU %" axes x1y1, \
     "$TMPDAT" using 1:3 with lines title "RSS KB" axes x1y2
EOF

    rm -f "$TMPDAT"
    echo "Grafico generado: monitor_${PID}.png"
}

# R4. Manejo de finalizar (Ctrl+c)
finalizar() {
    echo -e "\nInterrupción detectada. Finalizando..."
    kill "$PID" 2>/dev/null
    graficar
    exit 0
}

# Capturar la señal SIGINT (Ctrl+C)
trap finalizar SIGINT

# R3. Registro periódico
echo "Monitoreando proceso... (Ctrl+c para detener)"

while kill -0 "$PID" 2>/dev/null; do
    TS=$(date "+%Y-%m-%d %H:%M:%S")
    # Obtener datos de ps
    DATOS=$(ps -p "$PID" -o %cpu,%mem,rss --no-headers)
    
    if [ -n "$DATOS" ]; then
        # Leer los valores (limpiando espacios extra)
        read -r CPU MEM RSS <<< "$DATOS"
        echo "$TS $CPU $MEM $RSS" >> "$LOG"
    fi
    sleep "$INTERVALO"
done

echo "El proceso ha terminado de forma natural."
graficar
