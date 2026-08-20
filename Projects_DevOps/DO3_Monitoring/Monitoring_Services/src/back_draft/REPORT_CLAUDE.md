# Отчет по проекту "Мониторинг"

## Введение

Настроен полный стек мониторинга для микросервисного приложения (бронирование отелей, 7 Java-сервисов + PostgreSQL + RabbitMQ), развёрнутого в Docker Swarm (стек `s21`, 3 ноды: `master-do9` — manager, 2 worker-ноды). Реализовано: сбор бизнес-метрик приложения через Micrometer, сбор логов через Promtail → Loki, визуализация в Grafana (15 панелей), критические алерты через Alertmanager с доставкой на Email и в Telegram. Все компоненты проверены вживую на реальном кластере, ниже — итоговая рабочая конфигурация с учётом всех проблем, найденных и исправленных в процессе.

> ⚠️ Перед сдачей проверить актуальность образов:
> `docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}\t{{.Size}}"`

---

## Part 1. Получение метрик и логов

### 1.1. Micrometer — бизнес-метрики приложения

В 4 сервиса (`booking-service`, `session-service`, `gateway-service`, `report-service`) добавлены `spring-boot-starter-actuator` + `micrometer-registry-prometheus`, эндпоинт `/actuator/prometheus` открыт через `application.properties`.

| Метрика | Сервис | Что считает |
|---|---|---|
| `rabbitmq_messages_sent_total` | booking-service | отправленные в RabbitMQ сообщения |
| `rabbitmq_messages_processed_total` | report-service | обработанные из RabbitMQ сообщения |
| `bookings_created_total` | booking-service | успешно созданные бронирования |
| `gateway_requests_total` | gateway-service | запросы, дошедшие до gateway (**исключая** синтетические probe-запросы от blackbox_exporter, см. 2.4) |
| `auth_requests_total` | session-service | запросы на авторизацию (`/authorize`) |

📎 Файлы: `AppMetrics.java` (booking/session/report-service), `GatewayMetricsFilter.java` (gateway-service), плюс точки вызова в `QueueProducer.java`, `BookingServiceImplementation.java`, `SessionController.java`, `QueueConsumer.java`

**Проверка (порт сервиса зависит от того, опубликован ли он наружу — см. Приложение):**
```bash
curl http://<host>:<порт>/actuator/prometheus | grep bookings_created_total
```

**[СКРИНШОТ: `bookings_created_total` растёт после прогона тестовых броней]**

Для генерации тестового трафика использован скрипт `test-bookings.sh` (регистрация пользователя → логин через `/authorize` → создание N бронирований через gateway).

---

### 1.2. Логи приложения — Loki + Promtail

**Выбор агента:** Promtail (не Docker Loki-driver-плагин) — соответствует архитектуре "ядро + агенты" из методических материалов, и не требует ручной установки плагина на каждой ноде по SSH. Используется последняя версия перед EOL: `grafana/promtail:3.6.11` (Promtail в статусе end-of-life с 2 марта 2026, официальный преемник — Grafana Alloy, но версия полностью рабочая).

Promtail (`mode: global`, по одной реплике на ноду) подключается к Docker-сокету, автоматически обнаруживает все контейнеры и пушит их логи в Loki с метками `container_name` и `service`.

📎 `promtail/promtail-config.yml`

**⚠️ Важный нюанс меток, обнаруженный при тестировании:** значения меток `container_name`/`service` берутся из **полного** имени Swarm-сервиса, с префиксом стека — `s21_booking-service`, а не просто `booking-service`. Запросы LogQL должны это учитывать:
```logql
{service="s21_booking-service"}
```
или для всех сервисов приложения разом (без "мусора" от контейнеров мониторинга):
```logql
{service=~"s21_.+"}
```

**Проверка:**
```bash
curl -s "http://<loki-host>:3100/loki/api/v1/label/service/values"
```

**[СКРИНШОТ: логи `s21_booking-service` в Grafana Explore, включая реальный пойманный WARN о HikariCP]**

---

### 1.3–1.4. Стек мониторинга в Docker Swarm + проверка метрик

Отдельный стек `docker-stack-monitoring.yml`, подключённый к **той же** overlay-сети, что и стек приложения — критично важно: реальное имя сети `s21_app-network` (Swarm автоматически префиксует имена сетей именем стека), а не просто `app-network`.

| Сервис | Режим | Комментарий |
|---|---|---|
| Prometheus | 1 реплика, manager | образ `prom/prometheus:latest`, порт 9090 |
| Loki | 1 реплика, manager | `grafana/loki:3.7.4`, порт 3100 (конфиг — см. 2.5, потребовал 2 фикса) |
| Promtail | `mode: global` | `grafana/promtail:3.6.11` |
| node_exporter | `mode: global` | метрики хостов |
| blackbox_exporter | 1 реплика, manager | HTTP-проверки, порт 9115 |
| cAdvisor | `mode: global` | метрики контейнеров |
| Grafana | 1 реплика, manager | визуализация, порт 3000 |
| Alertmanager | 1 реплика, manager | оповещения, порт 9093 |

📎 `docker-stack-monitoring.yml`, `prometheus/prometheus.yml`, `blackbox/blackbox.yml`

**Деплой** (через скрипт `deploy.sh`, который сам переходит в свою директорию перед выполнением — важно, т.к. пути к config-файлам в stack-файле относительные):
```bash
./deploy.sh
```

**Проверка:** `http://<manager-ip>:9090` → **Status → Targets** — все job'ы (`app-services`, `node-exporter`, `cadvisor`, `blackbox-http`, `blackbox-external`, `prometheus`) в статусе `UP`.

**[СКРИНШОТ: страница Targets в Prometheus, все цели зелёные]**
**[СКРИНШОТ: результат запроса `bookings_created_total` во вкладке Graph]**

---

## Part 2. Визуализация (Grafana)

### 2.1. Развёртывание и provisioning

Grafana добавлена в стек мониторинга (`grafana/grafana:latest`, порт 3000). Data Sources (Prometheus, Loki) подключаются **автоматически** при старте через provisioning-файлы — без ручных кликов в UI, с фиксированными `uid` (`prometheus_ds`, `loki_ds`), чтобы дашборд гарантированно находил нужный источник данных.

📎 `grafana/provisioning/datasources/datasources.yml`
📎 `grafana/provisioning/dashboards/dashboards.yml` (провижининг самих дашбордов из JSON-файлов)

### 2.2. Дашборд "Infrastructure & App Monitoring" — 15 панелей

📎 `grafana/provisioning/dashboards/json/infrastructure-app-monitoring.json` (актуальный экспорт из UI после всех правок, тип экспорта — Classic)

| № | Панель | Запрос (после исправлений по факту тестирования) |
|---|---|---|
| 1 | Количество нод | `count(node_uname_info)` |
| 2 | Количество контейнеров | `count(container_last_seen{container_label_com_docker_stack_namespace!=""})` — с фильтром, исключающим системные cgroups/pause-контейнеры (см. 2.3) |
| 3 | Количество стеков | `count(count by (container_label_com_docker_stack_namespace) (container_last_seen{container_label_com_docker_stack_namespace!=""}))` |
| 4 | CPU по сервисам | `sum(rate(container_cpu_usage_seconds_total{name!=""}[5m])) by (name)` |
| 5 | CPU по ядрам и узлам | `sum(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance, cpu)` |
| 6 | Затраченная RAM | `node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes` |
| 7 | Доступная/занятая память | 2 запроса в одной панели, легенды `{{instance}}` (см. 2.3 про читаемые имена нод) |
| 8 | Количество CPU | `count(node_cpu_seconds_total{mode="idle"})` |
| 9 | Доступность (blackbox) | `probe_success` — включает как внутренние сервисы, так и внешнюю проверку `google.com` (отдельный job `blackbox-external`, см. 2.4) |
| 10 | Отправлено в RabbitMQ | `rabbitmq_messages_sent_total` |
| 11 | Обработано из RabbitMQ | `rabbitmq_messages_processed_total` |
| 12 | Бронирований | `bookings_created_total` |
| 13 | Запросов на gateway | `gateway_requests_total` (после фикса 2.4 — без учёта health-check трафика) |
| 14 | Запросов на авторизацию | `auth_requests_total` |
| 15 | Логи приложения | LogQL `{service=~"s21_.+"}` (Loki) |

**[СКРИНШОТ: общий вид дашборда, все 15 панелей]**
**[СКРИНШОТ: крупный план панели логов]**

### 2.3. Проблемы, найденные и исправленные при сборке дашборда

- **Панель 4 (CPU по сервисам):** в визуальном билдере Grafana легко перепутать служебную метку `__name__` (имя самой метрики) с обычной меткой `name` (реальное имя контейнера) — из-за похожего написания в выпадающем списке. Исправлено выбором `name`.
- **Панели 5–7 (легенды по нодам):** `{{instance}}` изначально показывал нечитаемый `IP:port` (`192.168.121.150:9100`). Попытка получить читаемое имя через join с `node_uname_info{nodename}` тоже не сработала "из коробки" — метрика `nodename` брала hostname **изнутри контейнера** (случайный container ID), а не реальное имя ноды Swarm. Решение — задать сервису `node-exporter` явный `hostname: "{{.Node.Hostname}}"` в `docker-stack-monitoring.yml`, чтобы контейнер знал имя своей реальной ноды.
- **Панель 2/3 (контейнеры/стеки):** cAdvisor без флага `--docker_only=true` считает вообще все cgroups системы (получилось 124 вместо реальных ~26 контейнеров в трёх стеках `do9`/`portainer`/`s21`) — добавлен фильтр по непустой метке `container_label_com_docker_stack_namespace`, а в конфиг cAdvisor рекомендован флаг `--docker_only=true`.

### 2.4. Отдельная проверка доступности — google.com

Изначально job `blackbox-http` проверял только внутренние `/actuator/health` эндпоинты приложения. Добавлен отдельный job `blackbox-external` специально под `https://google.com` — подтверждено, что стенд имеет исходящий доступ в интернет (`curl -I https://google.com` → `200`, `wget` из контейнера blackbox-exporter → доступен).

**Побочный эффект, тоже исправлен:** blackbox_exporter скрейпит цели каждые 15 секунд — то есть проверка `http://gateway-service:8087/api/v1/gateway/hotels` сама генерировала ~240 запросов/час, которые засчитывались в `gateway_requests_total` наравне с реальными пользователями. Исправлено: blackbox теперь добавляет заголовок `X-Monitoring-Probe: blackbox-exporter` к своим запросам (📎 `blackbox/blackbox.yml`), а `GatewayMetricsFilter` игнорирует запросы с этим заголовком (📎 `GatewayMetricsFilter.java`) — метрика теперь отражает только реальную пользовательскую нагрузку.

### 2.5. Проблемы при развёртывании Loki (важно для повторной сборки)

При первом деплое Loki `3.7.4` падал в crash loop с двумя разными ошибками подряд:

1. **Ошибка валидации схемы:** старая схема `v11` + `boltdb-shipper` несовместима с Loki 3.x по умолчанию. Исправлено переходом на актуальную схему `v13` + индекс `tsdb` (с добавлением обязательного для tsdb блока `compactor.working_directory`).
2. **`error contacting scheduler ... dial tcp 10.0.0.12:9095: i/o timeout`** — известный баг Loki в Docker Swarm: контейнер подключён к нескольким сетям одновременно, и Loki сам неверно выбирает сетевой интерфейс для внутренней gRPC-коммуникации между своими компонентами. Исправлено явным указанием `common.instance_addr: 127.0.0.1` (обоснованно для single-instance, не HA-кластера).

📎 `loki/loki-config.yml` — финальная рабочая версия с обоими исправлениями.

**Важно:** после любой правки этого файла необходимо пересоздавать Docker config (он иммутабелен):
```bash
docker stack rm monitoring && docker stack deploy -c docker-stack-monitoring.yml monitoring
```

---

## Part 3. Отслеживание критических событий

### 3.1–3.2. Alertmanager и правила

Alertmanager добавлен в стек мониторинга; в `prometheus.yml` подключены блок `alerting` и `rule_files`.

📎 `prometheus/alert_rules.yml` — 4 правила: `LowAvailableMemory` (<100 МБ), `HighUsedMemory` (>1 ГБ), `HighServiceCPU` (>10%), `ServiceDown` (`up == 0`)
📎 `alertmanager/alertmanager.yml` — маршрутизация, получатели Email (SMTP Gmail, App Password) и Telegram

### 3.3. Каналы оповещений

Email (SMTP Gmail через App Password) и Telegram-бот (токен от `@BotFather`, chat_id от `@userinfobot`).

### 3.4. Проверка срабатывания — и важный инцидент по итогам теста

**Правильный способ протестировать один алерт**, не создавая лишнюю нагрузку — через `amtool` напрямую в Alertmanager, а не через постоянно-истинное PromQL-правило:
```bash
docker exec -it $(docker ps -qf "name=alertmanager") amtool alert add \
  alertname="TestEmailAlert" severity="critical" \
  --annotation="summary=Тестовое письмо" \
  --alertmanager.url=http://localhost:9093
```

**⚠️ Инцидент при первом тесте (зафиксирован для полноты отчёта):** тестовое правило было по ошибке написано как `expr: vector(1)` (всегда истинно, никогда не резолвится) с коротким `for: 10s`. Из-за постоянных неудачных retry на отправку email Gmail-аккаунт получил временную блокировку (`454 4.7.0 Too many login attempts`) — защитный механизм Google против похожей на brute-force активности. Устранено: сервис Alertmanager остановлен, ошибочное правило удалено из конфига, выдержана пауза перед повторным использованием SMTP. Впредь тестирование алертов ведётся только через `amtool` (одноразовая отправка) либо правилами с заведомо управляемым условием, а не вечно-истинными expr.

**[СКРИНШОТ: интерфейс Alertmanager, порт 9093, тестовый алерт в статусе firing]**
**[СКРИНШОТ: письмо на почте с алертом]**
**[СКРИНШОТ: сообщение в Telegram от бота]**

---

## Заключение

Настроен и проверен на реальном 3-нодовом Swarm-кластере комплексный стек мониторинга: Prometheus собирает инфраструктурные метрики (node_exporter, cAdvisor) и бизнес-метрики приложения (Micrometer), Loki агрегирует логи всех контейнеров через Promtail, Grafana даёт единую точку визуализации (15 панелей, все datasource подключены через provisioning), Alertmanager оповещает о критических событиях по Email и Telegram. В процессе сборки обнаружен и задокументирован ряд неочевидных проблем (несовместимость схемы Loki, сетевой баг Loki в Swarm, путаница коротких/полных имён сервисов между Prometheus и Loki, засорение бизнес-метрики служебным трафиком мониторинга, инцидент с блокировкой SMTP) — все исправления отражены в конфигах и описаны выше.

## Приложение А: список изменённых/добавленных файлов

| Файл | Тип |
|---|---|
| `services/booking-service/pom.xml`, `application.properties` | изменены |
| `services/booking-service/.../Statistics/AppMetrics.java` | новый |
| `services/booking-service/.../Statistics/QueueProducer.java` | изменён |
| `services/booking-service/.../Service/BookingServiceImplementation.java` | изменён |
| `services/session-service/pom.xml`, `application.properties` | изменены |
| `services/session-service/.../Statistics/AppMetrics.java` | новый |
| `services/session-service/.../Controller/SessionController.java` | изменён |
| `services/gateway-service/pom.xml`, `application.properties` | изменены |
| `services/gateway-service/.../Statistics/GatewayMetricsFilter.java` | новый (с фиксом X-Monitoring-Probe) |
| `services/report-service/pom.xml`, `application.properties` | изменены |
| `services/report-service/.../Statistics/AppMetrics.java` | новый |
| `services/report-service/.../Statistics/QueueConsumer.java` | изменён |
| `monitoring-stack/docker-stack-monitoring.yml` | новый |
| `monitoring-stack/prometheus/prometheus.yml` | новый |
| `monitoring-stack/prometheus/alert_rules.yml` | новый |
| `monitoring-stack/loki/loki-config.yml` | новый (2 итерации фиксов) |
| `monitoring-stack/blackbox/blackbox.yml` | новый (+ фикс X-Monitoring-Probe) |
| `monitoring-stack/promtail/promtail-config.yml` | новый |
| `monitoring-stack/alertmanager/alertmanager.yml` | новый |
| `monitoring-stack/grafana/provisioning/datasources/datasources.yml` | новый |
| `monitoring-stack/grafana/provisioning/dashboards/dashboards.yml` | новый |
| `monitoring-stack/grafana/provisioning/dashboards/json/infrastructure-app-monitoring.json` | новый |
| `test-bookings.sh` | новый (скрипт генерации тестового трафика) |
| `deploy.sh` | новый (скрипт деплоя стека мониторинга) |

## Приложение Б: порты сервисов (для проверки actuator/health вручную)

| Сервис | Внутренний порт | Опубликован наружу |
|---|---|---|
| session-service | 8081 | 30001 |
| gateway-service | 8087 | 30007 |
| booking-service | 8083 | нет (только внутри `s21_app-network`) |
| report-service | 8086 | нет (только внутри `s21_app-network`) |
| Prometheus | 9090 | 9090 |
| Loki | 3100 | 3100 |
| Grafana | 3000 | 3000 |
| Alertmanager | 9093 | 9093 |
