#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MASTER="ws1"

UBUNTU_VERSION="22.04"

SSH_KEY="$HOME/.ssh/ws1_test"
SSH_PUB="$SSH_KEY.pub"

echo "==> Checking Multipass..."

if ! command -v multipass >/dev/null 2>&1; then
    echo "ERROR: multipass is not installed."
    exit 1
fi

# Create SSH key if it does not exist
if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "multipass key for ${MASTER}"
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

create_vm "${MASTER}" 1 1G 10G

echo

# Install SSH public key
for VM in "$MASTER"; do
    cat "$SSH_PUB" | multipass exec "$VM" -- \
        sudo tee -a /home/ubuntu/.ssh/authorized_keys >/dev/null
done

echo

echo "==> Waiting for VMs..."

for vm in "${MASTER}"; do
    echo "waiting for ${vm}..."

    until multipass exec "${vm}" -- cloud-init status --wait >/dev/null 2>&1; do
        sleep 2
    done
done

echo
echo "==> Setting hostnames..."

multipass exec "${MASTER}" -- \
    sudo hostnamectl set-hostname "${MASTER}"


echo


echo "==>  VM:"
echo

multipass list

echo
echo "==> IP addresses:"

for vm in "${MASTER}"; do
    ip="$(multipass info "${vm}" | awk '/IPv4/ {print $2; exit}')"
    printf '%-18s %s\n' "${vm}" "${ip}"
done

echo
echo "==> Multipass infrastructure is ready."