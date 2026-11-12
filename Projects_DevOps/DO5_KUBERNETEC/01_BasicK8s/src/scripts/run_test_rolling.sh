#!/bin/bash
# run_test_rolling.sh
# Полный эксперимент стратегии RollingUpdate:
#   1. baseline v3
#   2. обновление v3 -> v4 с замером
#   3. возврат на baseline v3

set -e

BASELINE_MANIFEST="kuber_manifests/loyalty-service.yaml"
ROLLING_MANIFEST="kuber_manifests/strategies/loyalty-service-rolling.yaml"
URL="http://192.168.49.2:30276/api/v1/loyalty/authorize"

echo "===================================================="
echo "1/3. Сброс на baseline (v3.do10_1.0)"
echo "===================================================="
kubectl apply -f "$BASELINE_MANIFEST"
kubectl rollout status deployment/loyalty-service

echo
sleep 5

echo "===================================================="
echo "2/3. Тест ROLLING UPDATE (v3.do10_1.0 -> v4.do10)"
echo "===================================================="
./test_downtime.sh "$ROLLING_MANIFEST" "$URL" rolling

echo
echo "===================================================="
echo "3/3. Возврат на baseline (v3.do10_1.0)"
echo "===================================================="
kubectl apply -f "$BASELINE_MANIFEST"
kubectl rollout status deployment/loyalty-service

echo
echo "Готово."
echo "Результаты: downtime_rolling.log"
