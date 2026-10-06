#!/bin/bash

# Установка докера версия 1 ( если нужно установить версию 2, то используйте другую функцию install_docker_compose и не забудьте поменять вызов в main.sh)
install_docker_compose_v1() {
    sudo apt update
    sudo apt install docker.io -y
    sudo apt install curl -y
    COMVER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4) && sudo curl -L "https://github.com/docker/compose/releases/download/$COMVER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
    sudo chmod +x /usr/bin/docker-compose
    echo ""
    echo "Установка Docker + Docker-compose завершена"
    docker-compose --version
}


install_docker_compose() {
    echo "=== Установка Docker Engine + Docker Compose V2 ==="

    # Удаляем старые пакеты версий Docker, если они установлены
    sudo apt remove -y docker.io docker-doc docker-compose podman-docker containerd runc

    # Зависимости
    sudo apt update
    sudo apt install -y ca-certificates curl

    # Docker GPG key
    sudo install -m 0755 -d /etc/apt/keyrings

    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc

    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Установка Docker + Compose V2
    sudo apt update
    sudo apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    echo ""
    echo "=== Установка завершена ==="

    docker --version
    docker compose version
}

# Настройка докера контейнера
setup_and_start_containers() {
    echo "=== Настройка Docker и запуск контейнеров ==="
    
    # Добавляем пользователя в группу docker
    echo "Добавляем пользователя $USER в группу docker..."
    sudo usermod -aG docker $USER
    
    # Активируем новые группы в текущей сессии
    echo "Активируем группу docker..."
    newgrp docker << 'END'
echo "Текущие группы пользователя:"
groups $USER
END
    
    # Управление службой Docker
    echo "Запускаем службу Docker..."
    sudo systemctl enable docker
    sudo systemctl start docker
    
    echo "Статус службы Docker:"
    sudo systemctl status docker --no-pager -l
    
    # Переходим в директорию и запускаем контейнеры
    echo "Запускаем Docker Compose..."
    есho "Переходим в директорию /opt/prometheus_stack"


    cd /opt/prometheus_stack
    sudo docker-compose up -d
    
    echo "Статус запущенных контейнеров:"
    sudo docker ps
}
