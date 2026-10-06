#!/bin/bash

# Прометеус установка
setup_prometheus_stack() {
    echo "=== Настройка Prometheus Stack ==="
    
    # Создаем соответствующие директории                   
    sudo mkdir -p /opt/prometheus_stack/{prometheus,grafana}
    
    # Переходим в директорию
    cd /opt/prometheus_stack
    
    # Создаем docker-compose.yml
    echo "Создаем docker-compose.yml..."
    cat << 'EOF' | sudo tee /opt/prometheus_stack/docker-compose.yml > /dev/null

services:

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus:/etc/prometheus/
    container_name: prometheus
    hostname: prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
    ports:
      - 59090:9090
    restart: unless-stopped
    environment:
      TZ: "Europe/Moscow"

  node-exporter:
    image: prom/node-exporter
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    container_name: node-exporter
    hostname: node-exporter
    command:
      - --path.procfs=/host/proc
      - --path.sysfs=/host/sys
      - --collector.filesystem.ignored-mount-points
      - ^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)($$|/)
    ports:
      - 59100:9100
    restart: unless-stopped
    environment:
      TZ: "Europe/Moscow"

  grafana:
    image: grafana/grafana
    user: ubuntu
    depends_on:
      - prometheus
    ports:
      - 53000:3000
    volumes:
      - ./grafana:/var/lib/grafana
      - ./grafana/provisioning/:/etc/grafana/provisioning/
    container_name: grafana
    hostname: grafana
    restart: unless-stopped
    environment:
      TZ: "Europe/Moscow"
EOF

    # Создаем базовый конфиг для Prometheus
    echo "Создаем конфигурацию Prometheus..."
   
    cat << 'EOF' | sudo tee /opt/prometheus_stack/prometheus/prometheus.yml > /dev/null

  scrape_configs:
  - job_name: node
    scrape_interval: 5s
    static_configs:
    - targets: ['node-exporter:9100']
EOF

    # Даем права на директории
    sudo chown -R $USER:$USER /opt/prometheus_stack
    sudo chmod -R 755 /opt/prometheus_stack
}


