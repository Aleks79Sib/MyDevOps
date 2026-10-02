#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MASTER="shop-master"
WORKER1="shop-worker1"
WORKER2="shop-worker2"
UBUNTU_VERSION="22.04"

SSH_KEY="$HOME/.ssh/shop_ansible"
SSH_PUB="$SSH_KEY.pub"

echo "==> Checking Multipass..."

if ! command -v multipass >/dev/null 2>&1; then
    echo "ERROR: multipass is not installed."
    exit 1
fi

# Create SSH key if it does not exist
if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "shop-ansible"
fi

create_vm() {
    local name="$1"
    local cpus="$2"
    local memory="$3"
    local disk="$4"

    if multipass info "${name}" >/dev/null 2>&1; then
        echo "==> ${name} уже существует, пропускаем..."
        return
    fi

    echo "==> Creating ${name}..."
    multipass launch "$UBUNTU_VERSION" \
        --name "${name}" \
        --cpus "${cpus}" \
        --memory "${memory}" \
        --disk "${disk}"
}

create_vm "${MASTER}" 2 2G 20G
create_vm "${WORKER1}" 3 4G 35G
create_vm "${WORKER2}" 3 4G 35G

echo

# Install SSH public key
for VM in "$MASTER" "$WORKER1" "$WORKER2"; do
    cat "$SSH_PUB" | multipass exec "$VM" -- \
        sudo tee -a /home/ubuntu/.ssh/authorized_keys >/dev/null
done

echo

echo "==> Waiting for VMs..."

for vm in "${MASTER}" "${WORKER1}" "${WORKER2}"; do
    echo "    waiting for ${vm}..."

    until multipass exec "${vm}" -- cloud-init status --wait >/dev/null 2>&1; do
        sleep 2
    done
done

echo
echo "==> Setting hostnames..."

multipass exec "${MASTER}" -- \
    sudo hostnamectl set-hostname "${MASTER}"

multipass exec "${WORKER1}" -- \
    sudo hostnamectl set-hostname "${WORKER1}"

multipass exec "${WORKER2}" -- \
    sudo hostnamectl set-hostname "${WORKER2}"

echo


echo "==> ShopSphere VMs:"
echo

multipass list

echo
echo "==> IP addresses:"

for vm in "${MASTER}" "${WORKER1}" "${WORKER2}"; do
    ip="$(multipass info "${vm}" | awk '/IPv4/ {print $2; exit}')"
    printf '%-18s %s\n' "${vm}" "${ip}"
done

echo
echo "==> Multipass infrastructure is ready."