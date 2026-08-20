#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"
docker stack rm do9

docker stack deploy -c docker-stack-monitoring.yml do9

sleep 10
docker stack services do9
docker stack ps do9