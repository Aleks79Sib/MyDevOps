#!/bin/bash                                                                                   
set -e                                                                                          
echo "=== Инициализация Swarm на $(hostname) ==="

mkdir -p /home/vagrant/src

if docker info 2>/dev/null | grep -q "Swarm: active"; then
  echo "Swarm уже инициализирован, пропускаю init"
else
  docker swarm init --advertise-addr 192.168.100.100
fi
                                             
docker swarm join-token -q worker > /home/vagrant/src/worker_token
chmod 644 /home/vagrant/src/worker_token

echo "Swarm инициализирован! Токен сохранён в shared-папке."

docker node ls
