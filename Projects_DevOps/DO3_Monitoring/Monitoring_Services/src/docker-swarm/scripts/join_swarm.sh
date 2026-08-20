#!/bin/bash                                                                                    
set -e                                                                                          
echo "=== Подключение $(hostname) к Swarm ==="

if docker info 2>/dev/null | grep -q "Swarm: active"; then
  echo "$(hostname) уже в составе Swarm, пропускаю join"
  exit 0
fi

TOKEN_FILE="/home/vagrant/src/worker_token"
TOKEN=""

for i in $(seq 1 30); do                                                                        
    if [ -s "$TOKEN_FILE" ]; then                                                
    TOKEN=$(cat "$TOKEN_FILE")                                                 
    echo "Токен получен"                                                                     
    break                                                                                       
    fi                                                                                            
    echo "Ожидание токена... ($i/30)"                                                          
    sleep 2                                                                                       
done

if [ -z "$TOKEN" ]; then
  echo "Токен так и не появился, прерываю"
  exit 1
fi

docker swarm join --token "$TOKEN" 192.168.121.150:2377 
                                        
echo "$(hostname) присоединился к Swarm!"
                                                
                                                                                                   
