#!/bin/bash

DEPLOY_IP="192.168.252.3"
DEPLOY_USER="ubuntu"
ARTIFACT_PATH="../code-samples/DO"
DEPLOY_PATH="/usr/local/bin"

echo "=== Этап деплоя ==="
echo "Копирую DO на $DEPLOY_USER@$DEPLOY_IP ..."

# Копируем во временную директорию
scp -o StrictHostKeyChecking=no "$ARTIFACT_PATH" "$DEPLOY_USER@$DEPLOY_IP:/tmp/DO"

if [ $? -ne 0 ]; then
    echo "ОШИБКА: Не удалось скопировать файл!"
    exit 1
fi

# Перемещаем в /usr/local/bin через sudo
ssh -o StrictHostKeyChecking=no "$DEPLOY_USER@$DEPLOY_IP" "sudo mv /tmp/DO $DEPLOY_PATH/DO && sudo chmod 755 $DEPLOY_PATH/DO"

if [ $? -eq 0 ]; then
    echo "Файл DO успешно скопирован в $DEPLOY_PATH на deploy-vm"
    echo "=== Деплой завершён успешно ==="
    exit 0
else
    echo "ОШИБКА: Не удалось переместить файл в $DEPLOY_PATH!"
    exit 1
fi
