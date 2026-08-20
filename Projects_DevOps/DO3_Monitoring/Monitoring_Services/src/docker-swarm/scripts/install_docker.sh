#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "=== Установка Docker на $(hostname) ==="

if command -v docker >/dev/null 2>&1; then
  echo "Docker уже установлен:"
  docker --version
  exit 0
fi

apt-get update -y

apt-get install -y \
  ca-certificates \
  curl \
  gnupg

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y

apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker vagrant || true

echo "Docker установлен:"
docker --version