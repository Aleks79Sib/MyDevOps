#!/usr/bin/env bash

set -euo pipefail

MASTER_SRC="master-1"
WORKER1_SRC="worker-1"
WORKER2_SRC="worker-2"

MASTER="helm-master"
WORKER1="helm-worker-1"
WORKER2="helm-worker-2"

K3S_VERSION="v1.35.1+k3s1"

echo "========================================"
echo "  Создание нового K3s-кластера"
echo "  Старый кластер НЕ будет изменён"
echo "========================================"
echo

# --------------------------------------------------
# 1. Проверяем исходные VM
# --------------------------------------------------

echo "[1/8] Проверяем исходные VM..."

for VM in "$MASTER_SRC" "$WORKER1_SRC" "$WORKER2_SRC"; do
    STATE=$(multipass info "$VM" | grep '^State:' | awk '{print $2}')

    if [ "$STATE" != "Stopped" ]; then
        echo "ERROR: VM $VM должна быть остановлена."
        multipass info "$VM"
        exit 1
    fi
done

echo "Исходные VM остановлены."
echo

# --------------------------------------------------
# 2. Проверяем, что новые VM ещё не существуют
# --------------------------------------------------

echo "[2/8] Проверяем новые имена..."

for VM in "$MASTER" "$WORKER1" "$WORKER2"; do
    if multipass info "$VM" >/dev/null 2>&1; then
        echo "ERROR: VM $VM уже существует."
        echo "Удалять её автоматически скрипт не будет."
        exit 1
    fi
done

echo "Новые имена свободны."
echo

# --------------------------------------------------
# 3. Клонируем старые VM
# --------------------------------------------------

echo "[3/8] Клонируем виртуальные машины..."

multipass clone "$MASTER_SRC" --name "$MASTER"
multipass clone "$WORKER1_SRC" --name "$WORKER1"
multipass clone "$WORKER2_SRC" --name "$WORKER2"

echo
echo "Клоны созданы:"
multipass list
echo

# --------------------------------------------------
# 4. Запускаем новые VM
# --------------------------------------------------

echo "[4/8] Запускаем новые VM..."

multipass start "$MASTER" "$WORKER1" "$WORKER2"

echo "Ожидаем получение IP..."

sleep 10

multipass list
echo

# --------------------------------------------------
# 5. Удаляем старый K3s из клонов
# --------------------------------------------------

echo "[5/8] Удаляем старый K3s из клонов..."

echo "Удаляем K3s server с $MASTER..."

multipass exec "$MASTER" -- bash -c '
    if [ -x /usr/local/bin/k3s-uninstall.sh ]; then
        sudo /usr/local/bin/k3s-uninstall.sh
    fi
'

echo "Удаляем K3s agent с $WORKER1..."

multipass exec "$WORKER1" -- bash -c '
    if [ -x /usr/local/bin/k3s-agent-uninstall.sh ]; then
        sudo /usr/local/bin/k3s-agent-uninstall.sh
    fi
'

echo "Удаляем K3s agent с $WORKER2..."

multipass exec "$WORKER2" -- bash -c '
    if [ -x /usr/local/bin/k3s-agent-uninstall.sh ]; then
        sudo /usr/local/bin/k3s-agent-uninstall.sh
    fi
'

echo "Старый K3s удалён из новых копий."
echo

# --------------------------------------------------
# 6. Получаем IP master
# --------------------------------------------------

echo "[6/8] Получаем IP нового master..."

MASTER_IP=$(multipass info "$MASTER" |
    awk '/IPv4:/ {
        for (i=2; i<=NF; i++) {
            if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
                print $i
                exit
            }
        }
    }')

if [[ -z "$MASTER_IP" ]]; then
    echo "ERROR: Не удалось получить IP $MASTER"
    exit 1
fi

echo "MASTER_IP=$MASTER_IP"
echo

# --------------------------------------------------
# 7. Устанавливаем K3s server
# --------------------------------------------------

echo "[7/8] Устанавливаем K3s server на $MASTER..."

multipass exec "$MASTER" -- bash -c \
    "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='$K3S_VERSION' sh -s - server \
        --disable=traefik \
        --write-kubeconfig-mode=644"

echo
echo "K3s server установлен."
echo

echo "Проверяем master..."

multipass exec "$MASTER" -- sudo systemctl is-active k3s
multipass exec "$MASTER" -- k3s --version

echo

# --------------------------------------------------
# 8. Получаем token и подключаем workers
# --------------------------------------------------

echo "[8/8] Подключаем workers..."

NODE_TOKEN=$(multipass exec "$MASTER" -- \
    sudo cat /var/lib/rancher/k3s/server/node-token)

if [[ -z "$NODE_TOKEN" ]]; then
    echo "ERROR: Не удалось получить K3s node-token."
    exit 1
fi

echo "Node token получен."
echo

echo "Устанавливаем K3s agent на $WORKER1..."

multipass exec "$WORKER1" -- bash -c \
    "curl -sfL https://get.k3s.io | \
    K3S_URL='https://${MASTER_IP}:6443' \
    K3S_TOKEN='${NODE_TOKEN}' \
    INSTALL_K3S_VERSION='$K3S_VERSION' \
    sh -"

echo

echo "Устанавливаем K3s agent на $WORKER2..."

multipass exec "$WORKER2" -- bash -c \
    "curl -sfL https://get.k3s.io | \
    K3S_URL='https://${MASTER_IP}:6443' \
    K3S_TOKEN='${NODE_TOKEN}' \
    INSTALL_K3S_VERSION='$K3S_VERSION' \
    sh -"

echo
echo "Workers подключены."
echo

# --------------------------------------------------
# Финальная проверка
# --------------------------------------------------

echo "========================================"
echo "  ПРОВЕРКА НОВОГО КЛАСТЕРА"
echo "========================================"
echo

echo "Multipass:"
multipass list

echo
echo "K3s nodes:"
multipass exec "$MASTER" -- sudo k3s kubectl get nodes -o wide

echo
echo "K3s pods:"
multipass exec "$MASTER" -- sudo k3s kubectl get pods -A

echo
echo "========================================"
echo "  ГОТОВО"
echo "========================================"
echo
echo "Новый кластер:"
echo "  $MASTER"
echo "  $WORKER1"
echo "  $WORKER2"
echo
echo "Старый кластер НЕ изменён:"
echo "  $MASTER_SRC"
echo "  $WORKER1_SRC"
echo "  $WORKER2_SRC"
echo
echo "Master IP: $MASTER_IP"