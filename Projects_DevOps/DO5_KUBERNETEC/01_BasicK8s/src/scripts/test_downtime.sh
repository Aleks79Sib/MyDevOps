#!/bin/bash
# test_downtime.sh
# Измеряет время rollout и недоступность HTTP-сервиса при обновлении Deployment.
#
# Использование:
#   ./test_downtime.sh <manifest.yaml> <url> [label]
#
# Пример:
#   ./test_downtime.sh kuber_manifests/strategies/loyalty-service-recreate.yaml \
#       http://192.168.49.2:30276/api/v1/loyalty/authorize recreate

set -e

MANIFEST="$1"
URL="$2"
LABEL="${3:-test}"
LOGFILE="downtime_${LABEL}.log"

if [ -z "$MANIFEST" ] || [ -z "$URL" ]; then
  echo "Использование: $0 <manifest.yaml> <url> [label]"
  exit 1
fi

echo "== Манифест: $MANIFEST"
echo "== URL: $URL"
echo "== Лог: $LOGFILE"
echo

: > "$LOGFILE"

# HTTP 000 означает, что соединение не установлено/сервис недоступен.
# Любой реальный HTTP-код (включая 400, 404, 500) означает,
# что HTTP endpoint доступен.
(
  set +e
  while true; do
    ts=$(date +%s.%N)
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 0.5 --max-time 1 "$URL" 2>/dev/null)
    [ -n "$code" ] || code="000"
    echo "$ts $code" >> "$LOGFILE"
    sleep 0.2
  done
) &
CURL_PID=$!

echo ">>> HTTP polling запущен (PID $CURL_PID). Применяю манифест..."
echo

APPLY_START=$(date +%s.%N)
kubectl apply -f "$MANIFEST"
kubectl rollout status deployment/loyalty-service
APPLY_END=$(date +%s.%N)

# Небольшой хвост, чтобы не потерять последние ответы.
sleep 2

kill "$CURL_PID" 2>/dev/null || true
wait "$CURL_PID" 2>/dev/null || true

DEPLOY_TIME=$(echo "$APPLY_END - $APPLY_START" | bc)

echo
echo "===================================================="
echo "Время переразвертывания: ${DEPLOY_TIME}s"
echo "===================================================="
echo

python3 - "$LOGFILE" "$DEPLOY_TIME" <<'EOF'
import sys

logfile = sys.argv[1]
deploy_time = sys.argv[2]

rows = []
with open(logfile) as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) != 2:
            continue
        ts, code = parts
        rows.append((float(ts), code))

if not rows:
    print("Лог пуст — проверь URL и доступность NodePort.")
    sys.exit(0)

# Считаем недоступностью только HTTP 000.
# 400 и любые другие HTTP-коды означают, что HTTP-сервис отвечает.
down_start = None
downtime_total = 0.0
down_periods = []

for ts, code in rows:
    is_down = code == "000"

    if is_down and down_start is None:
        down_start = ts
    elif not is_down and down_start is not None:
        period = ts - down_start
        downtime_total += period
        down_periods.append(period)
        down_start = None

if down_start is not None:
    period = rows[-1][0] - down_start
    downtime_total += period
    down_periods.append(period)

print(f"Всего HTTP-опросов: {len(rows)}")
print(f"Периодов недоступности: {len(down_periods)}")
print(f"Время переразвертывания: {deploy_time}s")

if down_periods:
    print(f"Суммарный простой: {downtime_total:.2f}s")
    print(f"Самый долгий обрыв: {max(down_periods):.2f}s")
else:
    print("Суммарный простой: 0.00s")
    print("Простоя не обнаружено.")

print()
print("Примечание: HTTP 400/404/500 не считаются downtime,")
print("поскольку HTTP-соединение с приложением установлено.")
EOF

echo "===================================================="
echo "Полный лог HTTP-опроса: $LOGFILE"
echo "===================================================="
