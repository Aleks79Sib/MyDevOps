#!/bin/bash                                                                                   
set -e                                                                                          
echo "=== Инициализация Swarm на $(hostname) ==="

# mkdir -p /shared

if docker info 2>/dev/null | grep -q "Swarm: active"; then
  echo "Swarm уже инициализирован, пропускаю init"
else
  docker swarm init --advertise-addr 192.168.121.150
fi

sudo mkdir -p /shared                                            
docker swarm join-token -q worker > /home/vagrant/src/worker_token

chmod 644 /home/vagrant/src/worker_token

echo "Swarm инициализирован! Токен сохранён в shared-папке."

docker node ls
