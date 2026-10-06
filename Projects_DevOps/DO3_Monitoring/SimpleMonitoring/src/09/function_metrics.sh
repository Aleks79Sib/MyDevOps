#!/bin/bash

# CPU Usage (реальный процент загрузки, а не load average)
cpu() {
    local cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.2f", usage}')
    echo "# HELP node_cpu_usage_percent CPU usage percentage"
    echo "# TYPE node_cpu_usage_percent gauge"
    echo "node_cpu_usage_percent $cpu_usage"
}

# RAM Used (в мегабайтах)
ram() {
    local ram_mb=$(free -m | awk 'NR==2{print $3}')
    echo "# HELP node_memory_used_megabytes Used memory in megabytes"
    echo "# TYPE node_memory_used_megabytes gauge"
    echo "node_memory_used_megabytes $ram_mb"
}

# Disk Used (в килобайтах)
disk() {
    local disk_kb=$(df / | tail -1 | awk '{print $3}')
    echo "# HELP node_disk_used_kilobytes Used disk space i kilobytes"
    echo "# TYPE node_disk_used_kilobytes gauge"
    echo "node_disk_used_kilobytes $disk_kb"
}
