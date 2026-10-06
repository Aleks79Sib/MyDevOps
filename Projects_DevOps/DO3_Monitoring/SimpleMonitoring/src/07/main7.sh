#!/bin/bash

source ./docker.sh
source ./components.sh
source instruction.sh

# Установка докера
install_docker_compose

# Установка компонентов prometheus, grafana, node_exporter
setup_prometheus_stack

# Настройка докера контейнера
setup_and_start_containers

# Вывод инструкции подключения dashboard
show_instructions

