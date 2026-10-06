#!/bin/bash

source ./function_metrics.sh


webdir="/var/www/html/metrics"
METRICS="$webdir/index.html"
TEMP_METRICS="$webdir/index.html.tmp"

# Создаем директорию, если не существует
mkdir -p $webdir
chown -R lorydari:lorydari /var/www/html/metrics
chmod 755 /var/www/html/metrics
function main {
    while true; do
        {
            cpu
            ram
            disk
        } > "$TEMP_METRICS"
        
        # Атомарная замена файла (Prometheus не получит неполный файл)
        mv "$TEMP_METRICS" "$METRICS"
        
        sleep 3
    done
}

main
