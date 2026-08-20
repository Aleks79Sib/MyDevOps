#!/bin/bash
set -e

# Директория самого скрипта (scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Корень проекта — на уровень выше scripts/, там лежит Vagrantfile
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"


echo "Работаю из: $PROJECT_ROOT"

echo "Удаляем машины"
vagrant destroy -f

echo "Поднимаю master-do9..."
vagrant up master-do9

echo "Забираю worker_token с master-do9..."

# mkdir -p "$PROJECT_ROOT/scripts"

RAW_FILE="shared/worker_token_raw.txt"
WORKER_TOKEN_PATH="shared/worker_token"

vagrant ssh master-do9 -c "cat /home/vagrant/src/worker_token" < /dev/null > "$RAW_FILE" 2>&1

TOKEN_CONTENT=$(grep -oE 'SWMTKN-[A-Za-z0-9_-]+' "$RAW_FILE" | head -n1)

if [ -z "$TOKEN_CONTENT" ]; then
  echo "Токен не найден в выводе. Содержимое $RAW_FILE:"
  cat "$RAW_FILE"
  exit 1
fi

echo "$TOKEN_CONTENT" > "$WORKER_TOKEN_PATH"
rm -f "$RAW_FILE"
echo "Токен получен: $TOKEN_CONTENT"

echo "Поднимаю worker-do9-1 и worker-do9-2..."
vagrant up worker-do9-1 worker-do9-2

echo "Кластер поднят!"
vagrant ssh master-do9 -c "docker node ls" < /dev/null 2>/dev/null

echo "Запуск Docker Swarm"
vagrant ssh master-do9 -c "cd ~/src && ./deploy.sh" < /dev/null 2>/dev/null

echo "Установка Portainer"
vagrant ssh master-do9 -c "curl -L https://downloads.portainer.io/ce2-19/portainer-agent-stack.yml -o portainer.yml && docker stack deploy -c portainer.yml portainer"

echo "Установка Мониторинга"
vagrant ssh master-do9 -c "cd ~/src/monitoring-stack && ./install_monitoring.sh"