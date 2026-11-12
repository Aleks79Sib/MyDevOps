#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# K3s cluster on Multipass
#
# Architecture:
#   helm-master
#   helm-worker-1
#   helm-worker-2
#
# OS: Ubuntu 22.04 LTS
# K3s: latest stable
# Traefik: disabled
# ============================================================

MASTER_NAME="helm-master"
WORKER1_NAME="helm-worker-1"
WORKER2_NAME="helm-worker-2"

UBUNTU_VERSION="22.04"

CPUS=2
MEMORY="2G"
DISK="10G"

echo "=============================================="
echo " K3s + Multipass cluster installation"
echo "=============================================="
echo

# ------------------------------------------------------------
# 1. Check Multipass
# ------------------------------------------------------------

if ! command -v multipass >/dev/null 2>&1; then
    echo "ERROR: multipass is not installed."
    exit 1
fi

echo "[1/8] Multipass version:"
multipass version
echo

# ------------------------------------------------------------
# 2. Create VMs
# ------------------------------------------------------------

create_vm() {
    local VM_NAME="$1"

    if multipass info "$VM_NAME" >/dev/null 2>&1; then
        echo "VM $VM_NAME already exists. Skipping creation."
    else
        echo "Creating VM: $VM_NAME"

        multipass launch "$UBUNTU_VERSION" \
            --name "$VM_NAME" \
            --cpus "$CPUS" \
            --memory "$MEMORY" \
            --disk "$DISK"
    fi

    echo
}

echo "[2/8] Creating virtual machines..."

create_vm "$MASTER_NAME"
create_vm "$WORKER1_NAME"
create_vm "$WORKER2_NAME"

echo
echo "Current Multipass instances:"
multipass list
echo

# ------------------------------------------------------------
# 3. Update packages and install curl
# ------------------------------------------------------------

echo "[3/8] Installing required packages..."

for VM in "$MASTER_NAME" "$WORKER1_NAME" "$WORKER2_NAME"; do
    echo "Preparing $VM..."

    multipass exec "$VM" -- bash -c '
        sudo apt-get update
        sudo apt-get install -y curl ca-certificates
    '
done

echo

# ------------------------------------------------------------
# 4. Install K3s server on master
# ------------------------------------------------------------

echo "[4/8] Installing K3s server on $MASTER_NAME..."

multipass exec "$MASTER_NAME" -- bash -c '
    if command -v k3s >/dev/null 2>&1; then
        echo "K3s is already installed on master. Skipping."
    else
        curl -sfL https://get.k3s.io | \
            sh -s - server \
            --disable=traefik \
            --write-kubeconfig-mode=644
    fi
'

echo

echo "Checking K3s service on master..."

multipass exec "$MASTER_NAME" -- \
    sudo systemctl is-active k3s

echo

echo "K3s version:"

multipass exec "$MASTER_NAME" -- \
    k3s --version

echo

# ------------------------------------------------------------
# 5. Get master IP
# ------------------------------------------------------------

echo "[5/8] Detecting master IP..."

MASTER_IP=$(
    multipass exec "$MASTER_NAME" -- \
        bash -c "hostname -I | awk '{print \$1}'"
)

if [[ -z "$MASTER_IP" ]]; then
    echo "ERROR: Could not determine master IP."
    exit 1
fi

echo "Master IP: $MASTER_IP"
echo

# ------------------------------------------------------------
# 6. Get K3s node token
# ------------------------------------------------------------

echo "[6/8] Getting K3s node token..."

NODE_TOKEN=$(
    multipass exec "$MASTER_NAME" -- \
        sudo cat /var/lib/rancher/k3s/server/node-token
)

if [[ -z "$NODE_TOKEN" ]]; then
    echo "ERROR: Could not obtain K3s node token."
    exit 1
fi

echo "K3s token obtained."
echo

# ------------------------------------------------------------
# 7. Install K3s agents
# ------------------------------------------------------------

install_worker() {
    local VM_NAME="$1"

    echo "Installing K3s agent on $VM_NAME..."

    multipass exec "$VM_NAME" -- bash -c "
        if systemctl is-active --quiet k3s-agent; then
            echo 'K3s agent is already running.'
        else
            curl -sfL https://get.k3s.io | \
                K3S_URL=https://${MASTER_IP}:6443 \
                K3S_TOKEN='${NODE_TOKEN}' \
                sh -
        fi
    "

    echo "Checking K3s agent on $VM_NAME..."

    multipass exec "$VM_NAME" -- \
        sudo systemctl is-active k3s-agent

    echo
}

install_worker "$WORKER1_NAME"
install_worker "$WORKER2_NAME"

# ------------------------------------------------------------
# 8. Verify cluster
# ------------------------------------------------------------

echo "[7/8] Waiting for nodes..."

sleep 5

echo
echo "=============================================="
echo " Kubernetes nodes"
echo "=============================================="

multipass exec "$MASTER_NAME" -- \
    sudo k3s kubectl get nodes -o wide

echo

echo "=============================================="
echo " Kubernetes pods"
echo "=============================================="

multipass exec "$MASTER_NAME" -- \
    sudo k3s kubectl get pods -A

echo

echo "=============================================="
echo " K3s cluster information"
echo "=============================================="

multipass exec "$MASTER_NAME" -- \
    sudo k3s kubectl cluster-info

echo

echo "=============================================="
echo " Multipass instances"
echo "=============================================="

multipass list

echo

echo "=============================================="
echo " INSTALLATION COMPLETED"
echo "=============================================="

echo
echo "Master IP:"
echo "$MASTER_IP"

echo
echo "Nodes:"
multipass exec "$MASTER_NAME" -- \
    sudo k3s kubectl get nodes -o wide

echo
echo "To access the cluster:"
echo
echo "  multipass exec $MASTER_NAME -- sudo k3s kubectl get nodes"
echo