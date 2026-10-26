#!/bin/bash
set -e

# Директория самого скрипта (scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Корень проекта — на уровень выше scripts/, там лежит Vagrantfile
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Работаю из: $PROJECT_ROOT"

echo "Поднимаю manager01..."
vagrant up manager01

echo "Забираю worker_token с manager01..."

# mkdir -p "$PROJECT_ROOT/scripts"

RAW_FILE="$SCRIPT_DIR/worker_token_raw.txt"
WORKER_TOKEN_PATH="$SCRIPT_DIR/worker_token"

vagrant ssh manager01 -c "cat /home/vagrant/src/worker_token" < /dev/null > "$RAW_FILE" 2>&1

TOKEN_CONTENT=$(grep -oE 'SWMTKN-[A-Za-z0-9_-]+' "$RAW_FILE" | head -n1)

if [ -z "$TOKEN_CONTENT" ]; then
  echo "Токен не найден в выводе. Содержимое $RAW_FILE:"
  cat "$RAW_FILE"
  exit 1
fi

echo "$TOKEN_CONTENT" > "$WORKER_TOKEN_PATH"
rm -f "$RAW_FILE"
echo "Токен получен: $TOKEN_CONTENT"

echo "Поднимаю worker01 и worker02..."
vagrant up worker01 worker02

echo "Кластер поднят!"
vagrant ssh manager01 -c "docker node ls" < /dev/null 2>/dev/null