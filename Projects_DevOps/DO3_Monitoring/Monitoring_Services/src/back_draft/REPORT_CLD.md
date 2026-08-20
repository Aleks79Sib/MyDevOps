# Отчет по проекту "Мониторинг"

## Введение

В данном проекте настроен стек мониторинга для микросервисного приложения (бронирование отелей), развёрнутого в Docker Swarm: сбор бизнес-метрик приложения через Micrometer, сбор логов через Promtail → Loki, инфраструктурные метрики (хосты, контейнеры, доступность эндпоинтов) и визуализация в Grafana.

## Part 1. Получение метрик и логов

### 1.1 Использовать Docker Swarm из первого проекта

> **Перед сдачей:** проверить актуальность образов командой
> `docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}\t{{.Size}}"`
> — колонка `CreatedSince` должна показывать недавнюю пересборку, а не старый закешированный образ.

---



### 1.1. Интеграция Micrometer в приложение

Для сбора бизнес-метрик в 4 сервиса (`booking-service`, `session-service`, `gateway-service`, `report-service`) добавлена зависимость `micrometer-registry-prometheus` + `spring-boot-starter-actuator`, а эндпоинт `/actuator/prometheus` открыт через настройки в `application.properties`.

Реализованы следующие счётчики:

| Метрика (имя в Prometheus) | Сервис | Что считает |
|---|---|---|
| `rabbitmq_messages_sent_total` | booking-service | отправленные в RabbitMQ сообщения |
| `rabbitmq_messages_processed_total` | report-service | обработанные из RabbitMQ сообщения |
| `bookings_created_total` | booking-service | успешно созданные бронирования |
| `gateway_requests_total` | gateway-service | все запросы, дошедшие до gateway |
| `auth_requests_total` | session-service | запросы на авторизацию (`/authorize`) |

**Где физически лежит код (файлы для проверки):**

- `services/booking-service/pom.xml` — зависимости Micrometer
- `services/booking-service/src/main/resources/application.properties` — настройки actuator
- `services/booking-service/.../Statistics/AppMetrics.java` — регистрация счётчиков `rabbitmq_messages_sent_total`, `bookings_created_total`
- `services/booking-service/.../Statistics/QueueProducer.java` — вызов счётчика после отправки в очередь
- `services/booking-service/.../Service/BookingServiceImplementation.java` — вызов счётчика после успешного сохранения брони
- `services/session-service/.../Statistics/AppMetrics.java` + `Controller/SessionController.java` — счётчик `auth_requests_total`
- `services/gateway-service/.../Statistics/GatewayMetricsFilter.java` — фильтр, считающий `gateway_requests_total` для всех запросов
- `services/report-service/.../Statistics/AppMetrics.java` + `Statistics/QueueConsumer.java` — счётчик `rabbitmq_messages_processed_total`

**Проверка вручную (какую команду выполнить и что она делает):**

```bash
curl http://<host>:<порт-сервиса>/actuator/prometheus
```
Эта команда напрямую обращается к эндпоинту Micrometer у конкретного сервиса и выводит все зарегистрированные метрики в текстовом Prometheus-формате — так можно убедиться, что метрика вообще существует, ещё до того, как её начнёт собирать сам Prometheus.

`curl -i http://localhost:30001/actuator/prometheus`

`curl -i http://localhost:30007/actuator/prometheus`

**[СКРИНШОТ: вывод `curl .../actuator/prometheus` с видимой строкой `bookings_created_total`]**

```bash
vagrant@worker-do9-2:~$ docker ps
CONTAINER ID   IMAGE                                       COMMAND                  CREATED        STATUS        PORTS      NAMES
b166e5189769   portainer/agent:2.19.5                      "./agent"                26 hours ago   Up 26 hours              portainer_agent.qv7jgbv27eubf0hqexr8b0ah9.j756pr5kl763e97foo46movz4
4d0eaf9a9628   htclelik/booking-service:v2.do9-1-metrics   "/__cacert_entrypoin…"   26 hours ago   Up 26 hours   8083/tcp   s21_booking-service.1.r0xtn1gd172729tda8snxqdaf
40ddf943d035   htclelik/report-service:v2.do9-1-metrics    "/__cacert_entrypoin…"   26 hours ago   Up 26 hours   8086/tcp   s21_report-service.1.p32s7h09x4bclhaem5eztb3w0
d4db2d86c11b   htclelik/payment-service:v2.do9-1-metrics   "/__cacert_entrypoin…"   26 hours ago   Up 26 hours   8084/tcp   s21_payment-service.1.5wb8a8xi58s9xclg5yj6yx2f6
```

`docker exec -it 4d0eaf9a9628 sh -c "wget -qO- http://localhost:8083/actuator/prometheus"`

`docker exec -it 40ddf943d035 sh -c "wget -qO- http://localhost:8086/actuator/prometheus"`
---

### 1.2. Добавление логов приложения с помощью Loki

Для сбора логов выбран агент **Promtail** (а не Docker Loki-driver-плагин) — по двум причинам: во-первых, это архитектура, описанная в методических материалах курса ("ядро Loki + агенты"); во-вторых, Promtail деплоится как обычный сервис стека (`mode: global`), а не требует ручной установки плагина на каждой ноде Swarm по SSH.

> На момент сдачи Promtail находится в статусе end-of-life (с 2 марта 2026, официальный преемник — Grafana Alloy), но продолжает штатно работать. Используется последняя выпущенная версия образа: `grafana/promtail:3.6.11`.

**Как это работает:** Promtail подключается к Docker-сокету на каждой ноде, автоматически обнаруживает все запущенные контейнеры (без ручного перечисления сервисов), читает их логи и пушит в Loki (`http://loki:3100/loki/api/v1/push`), проставляя метки `container_name` и `service` для удобных LogQL-запросов.

- `monitoring-stack/promtail/promtail-config.yml` — конфигурация Promtail (discovery + relabeling)
- `monitoring-stack/loki/loki-config.yml` — конфигурация самого Loki

**Проверка вручную:**

```bash
curl -G -s "http://<manager-ip>:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="booking-service"}'
```
Эта команда напрямую опрашивает API Loki через LogQL-запрос — селектор `{service="booking-service"}` фильтрует только логи нужного сервиса по метке, которую проставил Promtail.

**[СКРИНШОТ: логи `booking-service` через Grafana Explore или сырой ответ curl с логами]**

---

### 1.3. Создание стека мониторинга в Docker Swarm

Создан отдельный stack-файл `docker-stack-monitoring.yml`, который **подключается к той же overlay-сети** (`app-network`), что и стек приложения — это необходимо, чтобы Prometheus мог достучаться до `/actuator/prometheus` каждого сервиса, а Promtail/приложение — до Loki.

В стек вошли:

| Сервис | Режим деплоя | Зачем |
|---|---|---|
| Prometheus | 1 реплика на manager | хранит и агрегирует метрики |
| Loki | 1 реплика на manager | хранит логи |
| Promtail | `mode: global` (на каждой ноде) | собирает логи локальных контейнеров |
| node_exporter | `mode: global` | метрики хоста (CPU, RAM, диск) каждой ноды |
| blackbox_exporter | 1 реплика на manager | проверка "жив ли" HTTP-эндпоинт |
| cAdvisor | `mode: global` | метрики каждого отдельного контейнера |

- `monitoring-stack/docker-stack-monitoring.yml` — полный stack-файл
- `monitoring-stack/prometheus/prometheus.yml` — правила сбора метрик (`scrape_configs`)
- `monitoring-stack/blackbox/blackbox.yml` — модуль проверки `http_2xx`

**Команда деплоя и что она делает:**

```bash
docker run --rm -v $(pwd)/prometheus.yml:/tmp/prometheus.yml prom/prometheus:latest promtool check config /tmp/prometheus.yml

docker stack deploy -c docker-stack-monitoring.yml monitoring
```
Разворачивает все сервисы из файла как единый стек с именем `monitoring`. Swarm сам распределяет сервисы по нодам согласно `deploy:` секции каждого сервиса (`mode: global` — на все ноды, без указания — по умолчанию 1 реплика туда, где решит scheduler).

```bash
docker stack services monitoring
```
Показывает статус каждого сервиса стека в формате `N/N` (сколько реплик запущено из скольки нужно) — используется, чтобы убедиться, что всё поднялось.

**[СКРИНШОТ: вывод `docker stack services monitoring` — все сервисы в статусе N/N]**

---

### 1.4. Проверка получения метрик

Открыт веб-интерфейс Prometheus на порту 9090 (`http://<manager-ip>:9090`).

**Status → Targets** — список всех job'ов из `prometheus.yml` (`app-services`, `node-exporter`, `cadvisor`, `blackbox-http`, `prometheus`) со статусом `UP`.

**[СКРИНШОТ: страница Targets в Prometheus, все цели зелёные/UP]**

Проверка конкретных бизнес-метрик через вкладку Graph, запрос:
```
bookings_created_total
```

**[СКРИНШОТ: результат запроса `bookings_created_total` в Prometheus — таблица или график]**

---

## Part 2. Визуализация

### 2.1. Развертывание Grafana

Grafana добавлена как сервис в `docker-stack-monitoring.yml` (образ `grafana/grafana:latest`, порт 3000). Data Sources добавлены через UI: Prometheus (`http://prometheus:9090`) и Loki (`http://loki:3100`).

- `monitoring-stack/docker-stack-monitoring.yml` — секция сервиса `grafana` (при добавлении)

**[СКРИНШОТ: страница Data Sources в Grafana с подключёнными Prometheus и Loki]**

### 2.2. Создание дашборда

Дашборд "Infrastructure & App Monitoring" с 15 панелями (инфраструктура: node_exporter/cAdvisor, доступность: blackbox_exporter, бизнес-метрики: Micrometer, логи: Loki).

- `monitoring-stack/grafana/dashboard.json` — экспортированный JSON дашборда (Dashboard settings → JSON Model → Save)

**Команды для Дашборда**:

**[СКРИНШОТ: общий вид дашборда со всеми панелями]**
**[СКРИНШОТ: крупный план панели с логами приложения из Loki]**

---

## Part 3. Отслеживание критических событий

### 3.1. Развертывание Alertmanager

Alertmanager добавлен в стек мониторинга; в `prometheus.yml` подключён блок `alerting` (адрес Alertmanager) и файл правил `alert_rules.yml`.

- `monitoring-stack/prometheus/alert_rules.yml` — правила алертов
- `monitoring-stack/alertmanager/alertmanager.yml` — маршрутизация и получатели (Email/Telegram)

### 3.2–3.3. Правила и каналы оповещений

Настроены 3 критических правила (доступная память < 100 МБ, занятая RAM > 1 ГБ, CPU сервиса > 10%) и 2 канала доставки — Email (SMTP Gmail с App Password) и Telegram-бот (токен через `@BotFather`, chat_id через `@userinfobot`).

**Как проверить срабатывание (что делает команда):**
```bash
docker service update --force <service_name>
```
Форсированный перезапуск сервиса под нагрузкой/с изменённым порогом в `alert_rules.yml` — используется, чтобы искусственно вызвать condition алерта и убедиться, что уведомление реально доходит.

**[СКРИНШОТ: интерфейс Alertmanager, порт 9093, активный алерт]**
**[СКРИНШОТ: письмо на почте с алертом]**
**[СКРИНШОТ: сообщение в Telegram от бота]**

---

## Заключение

Настроен комплексный мониторинг: Prometheus собирает инфраструктурные и бизнес-метрики приложения (через Micrometer), Loki агрегирует логи всех контейнеров (через Promtail), Grafana даёт единую точку визуализации, Alertmanager оповещает о критических событиях по Email и Telegram.

## Приложение: список изменённых/добавленных файлов

| Файл | Тип изменения |
|---|---|
| `services/booking-service/pom.xml` | изменён |
| `services/booking-service/src/main/resources/application.properties` | изменён |
| `services/booking-service/.../Statistics/AppMetrics.java` | новый |
| `services/booking-service/.../Statistics/QueueProducer.java` | изменён |
| `services/booking-service/.../Service/BookingServiceImplementation.java` | изменён |
| `services/session-service/pom.xml` | изменён |
| `services/session-service/src/main/resources/application.properties` | изменён |
| `services/session-service/.../Statistics/AppMetrics.java` | новый |
| `services/session-service/.../Controller/SessionController.java` | изменён |
| `services/gateway-service/pom.xml` | изменён |
| `services/gateway-service/src/main/resources/application.properties` | изменён |
| `services/gateway-service/.../Statistics/GatewayMetricsFilter.java` | новый |
| `services/report-service/pom.xml` | изменён |
| `services/report-service/src/main/resources/application.properties` | изменён |
| `services/report-service/.../Statistics/AppMetrics.java` | новый |
| `services/report-service/.../Statistics/QueueConsumer.java` | изменён |
| `monitoring-stack/docker-stack-monitoring.yml` | новый |
| `monitoring-stack/prometheus/prometheus.yml` | новый |
| `monitoring-stack/loki/loki-config.yml` | новый |
| `monitoring-stack/blackbox/blackbox.yml` | новый |
| `monitoring-stack/promtail/promtail-config.yml` | новый |
