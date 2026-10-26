#!/bin/bash                                                                                    
set -e                                                                                          
echo "=== Подключение $(hostname) к Swarm ==="

if docker info 2>/dev/null | grep -q "Swarm: active"; then
  echo "$(hostname) уже в составе Swarm, пропускаю join"
  exit 0
fi

TOKEN=""

for i in $(seq 1 30); do                                                                        
    if [ -f /home/vagrant/src/worker_token ]; then                                                
    TOKEN=$(cat /home/vagrant/src/worker_token)                                                 
    echo "Токен получен"                                                                     
    break                                                                                       
    fi                                                                                            
    echo "...Ожидание токена... ($i/30)"                                                          
    sleep 2                                                                                       
done

if [ -z "$TOKEN" ]; then
  echo "Токен так и не появился, прерываю"
  exit 1
fi

docker swarm join --token "$TOKEN" 192.168.100.100:2377 
                                        
echo "$(hostname) присоединился к Swarm!"
                                                
                                                                                                   
