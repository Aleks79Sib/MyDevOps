#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

docker stack rm s21

set -a
source .env
set +a

docker stack deploy -c docker-compose-swarm.yml s21

sleep 10
docker stack services s21
docker stack ps s21