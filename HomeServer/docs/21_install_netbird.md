# 📘 Полная инструкция: NetBird Self-Hosted + Reverse Proxy
📋 Оглавление
[Установка NetBird на RSB (VPS)]()
Установка NetBird на HS (домашний сервер)
Настройка Reverse Proxy с поддоменами
Решённые проблемы с приложениями
## 1. Установка NetBird на RSB (VPS)

### 📍 Конфигурация сервера

- IP: 155.212.223.132 (публичный)
- Домен: nb.envai.win
- DNS-провайдер: Cloudflare (серое облако — DNS only)
- Reverse proxy: Traefik v3.6 (обязательно!)
- Docker-сеть: netbird (subnet 172.30.0.0/24)

### 📁 Структура файлов

```bash
~/docker/netbird-server/
├── docker-compose.yml
├── config.yaml           # Конфиг NetBird Management + Signal
├── dashboard.env         # Переменные окружения для Dashboard
└── volumes:
    ├── netbird_data
    └── netbird_traefik_letsencrypt
```
- 📄 docker-compose.yml — финальная рабочая версия
```yaml
services:
  # ==================== Traefik ====================
  traefik:
    image: traefik:v3.6
    container_name: netbird-traefik
    restart: unless-stopped
    networks:
      netbird:
        ipv4_address: 172.30.0.10
    command:
      - "--log.level=INFO"
      - "--accesslog=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=netbird"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.websecure.allowACMEByPass=true"
      - "--entrypoints.websecure.transport.respondingTimeouts.readTimeout=0"
      - "--entrypoints.websecure.transport.respondingTimeouts.writeTimeout=0"
      - "--entrypoints.websecure.transport.respondingTimeouts.idleTimeout=0"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--certificatesresolvers.letsencrypt.acme.email=you@email.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--serverstransport.forwardingtimeouts.responseheadertimeout=0s"
      - "--serverstransport.forwardingtimeouts.idleconntimeout=0s"
    ports:
      - '443:443'
      - '80:80'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - netbird_traefik_letsencrypt:/letsencrypt

  # ==================== Dashboard ====================
  dashboard:
    image: netbirdio/dashboard:latest
    container_name: netbird-dashboard
    restart: unless-stopped
    networks: [netbird]
    env_file:
      - ./dashboard.env
    labels:
      - traefik.enable=true
      - traefik.http.routers.netbird-dashboard.rule=Host(`nb.envai.win`)
      - traefik.http.routers.netbird-dashboard.entrypoints=websecure
      - traefik.http.routers.netbird-dashboard.tls=true
      - traefik.http.routers.netbird-dashboard.tls.certresolver=letsencrypt
      - traefik.http.routers.netbird-dashboard.service=dashboard
      - traefik.http.routers.netbird-dashboard.priority=1
      - traefik.http.services.dashboard.loadbalancer.server.port=80

  # ==================== NetBird Server ====================
  netbird-server:
    image: netbirdio/netbird-server:latest
    container_name: netbird-server
    restart: unless-stopped
    networks: [netbird]
    ports:
      - '3478:3478/udp'
    volumes:
      - netbird_data:/var/lib/netbird
      - ./config.yaml:/etc/netbird/config.yaml
    command: ["--config", "/etc/netbird/config.yaml"]
    labels:
      - traefik.enable=true
      - traefik.http.routers.netbird-grpc.rule=Host(`nb.envai.win`) && (PathPrefix(`/signalexchange.v2.SignalExchange/`) || PathPrefix(`/api`))
      - traefik.http.routers.netbird-grpc.entrypoints=websecure
      - traefik.http.routers.netbird-grpc.tls=true
      - traefik.http.routers.netbird-grpc.tls.certresolver=letsencrypt
      - traefik.http.routers.netbird-grpc.service=netbird-server-h2c
      - traefik.http.routers.netbird-grpc.priority=100
      - traefik.http.routers.netbird-backend.rule=Host(`nb.envai.win`) && (PathPrefix(`/relay`) || PathPrefix(`/management.ManagementService/`))
      - traefik.http.routers.netbird-backend.entrypoints=websecure
      - traefik.http.routers.netbird-backend.tls=true
      - traefik.http.routers.netbird-backend.tls.certresolver=letsencrypt
      - traefik.http.routers.netbird-backend.service=netbird-server
      - traefik.http.routers.netbird-backend.priority=100
      - traefik.http.services.netbird-server.loadbalancer.server.port=80
      - traefik.http.services.netbird-server-h2c.loadbalancer.server.port=80
      - traefik.http.services.netbird-server-h2c.loadbalancer.server.scheme=h2c

  # ==================== Reverse Proxy (BYOP) ====================
  reverse-proxy:
    image: netbirdio/reverse-proxy:latest
    container_name: netbird-reverse-proxy
    restart: unless-stopped
    networks: [netbird]
    environment:
      NB_PROXY_CERTIFICATE_DIRECTORY: /certs
      NB_PROXY_ALLOW_INSECURE: "true"
      NB_PROXY_MANAGEMENT_ADDRESS: "https://nb.envai.win"
      NB_PROXY_ACME_CERTIFICATES: "true"
      NB_PROXY_DOMAIN: "nb.envai.win"
      NB_PROXY_LOG_LEVEL: info
      NB_PROXY_TOKEN: "nbx_ВАШ_ТОКЕН_ИЗ_АДМИНКИ"
      NB_PROXY_PRIVATE: "true"
      NB_PROXY_ADDRESS: ":443"
    volumes:
      - proxy_certs:/certs
    labels:
      - traefik.enable=true
      # TCP router (TLS passthrough) — критично!
      - traefik.tcp.routers.nb-proxy.rule=HostSNIRegexp(`^[a-z0-9-]+\.nb\.envai\.win$`)
      - traefik.tcp.routers.nb-proxy.entrypoints=websecure
      - traefik.tcp.routers.nb-proxy.tls.passthrough=true
      - traefik.tcp.routers.nb-proxy.priority=50
      - traefik.tcp.routers.nb-proxy.service=nb-proxy-svc
      - traefik.tcp.services.nb-proxy-svc.loadbalancer.server.port=443

volumes:
  netbird_data:
  netbird_traefik_letsencrypt:
  proxy_certs:

networks:
  netbird:
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.0.0/24
          gateway: 172.30.0.1
```


### ⚠️ Проблемы и решения на RSB

![роблемы и решение](./images/ProblemsRSB.png)

## 2. Установка NetBird на HS (домашний сервер)

### 📍 Конфигурация сервера

- CPU: AMD Ryzen 7 7700X (со встроенной графикой RDNA 2)
- ОС: Linux (за NAT роутера)
- Пользователь: lorydari
- Docker-сервисы: Nextcloud, Vaultwarden, Adminer, n8n, Postgres, Jellyfin, qBittorrent

### 📁 Где хранится NetBird
```bash
# Конфигурация NetBird (агент)
/etc/netbird/config.json

# Логи агента
/var/log/syslog | grep netbird

# Docker-контейнеры сервисов
~/docker/server/docker-compose.yml

# Данные Nextcloud
/var/lib/nextcloud/         # приложение
/storage/nextcloud/data/    # файлы пользователей + nextcloud.log

# Данные Vaultwarden
/var/lib/vaultwarden/

# Данные Postgres
/var/lib/postgresql/data/
```
### 🚀 Установка агента NetBird на HS

```bash
# Установка через официальный скрипт
curl -fsSL https://pkgs.netbird.io/install.sh | sh

# Подключение к self-hosted серверу
sudo netbird up --management-url https://nb.envai.win

# Проверка статуса
sudo netbird status
```

После подключения HS получает NetBird IP вида 100.64.x.x и появляется в веб-админке https://nb.envai.win → Peers.

### 🐳 Пример docker-compose.yml для сервисов HS

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - /var/lib/postgresql/data:/var/lib/postgresql/data
    # БЕЗ проброса портов — контейнеры общаются через docker-сеть
    networks: [backend]

  nextcloud:
    image: nextcloud:34.0.1
    container_name: nextcloud
    restart: unless-stopped
    ports:
      - "49880:80"   # для reverse proxy
    volumes:
      - /var/lib/nextcloud:/var/www/html
      - /storage/nextcloud/data:/var/www/html/data
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=${NC_POSTGRES_DB}
      - POSTGRES_USER=${NC_POSTGRES_USER}
      - POSTGRES_PASSWORD=${NC_POSTGRES_PASSWORD}
      - OVERWRITEPROTOCOL=https
      - NEXTCLOUD_DATADIR=/var/www/html/data
    depends_on:
      postgres:
        condition: service_healthy
    networks: [backend]

  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    ports:
      - "49080:49080"
    volumes:
      - /var/lib/vaultwarden:/data
    environment:
      - DOMAIN=${VW_DOMAIN}
      - WEBSOCKET_ENABLED=true
      - SIGNUPS_ALLOWED=false
      - ROCKET_PORT=49080
      - ROCKET_IP=0.0.0.0
    networks: [backend]

  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    ports:
      - "8096:8096"
    devices:
      - /dev/dri/renderD128:/dev/dri/renderD128
      - /dev/dri/card0:/dev/dri/card0
    group_add:
      - "44"    # video
      - "991"   # render
    networks: [backend]

networks:
  backend:
    driver: bridge
```
### ⚠️ Проблемы и решения на HS

![Проблемы и решения на HS](./images/ProblemsHS.png)

## 3. Настройка Reverse Proxy с поддоменами

### 🌐 DNS-записи в Cloudflare

Type   Name     Content           Proxy
A      nb   155.212.223.132.   🟥 DNS only
CNAME  *.nb   nb.envai.win.    🟥 DNS only

Важно: Серое облако (DNS only) — трафик идёт напрямую на RSB, минуя Cloudflare.

### 🗝️ Получение токена для Reverse Proxy

- Открой https://nb.envai.win → Reverse Proxy → Clusters
- Нажми Setup Self-Hosted Cluster
- Введи домен: nb.envai.win
- Сгенерируй token → скопируй его сразу (показывается один раз!)
- Вставь токен в NB_PROXY_TOKEN в docker-compose.yml на RSB

### 🔧 Создание сервисов

В админке NetBird → Reverse Proxy → Services → Add Service:

![Table Proxy](./images/proxy.png)

### Итоговые URL

```
https://vault.nb.envai.win        → Vaultwarden
https://nextcloud.nb.envai.win    → Nextcloud
https://qbittorrent.nb.envai.win  → qBittorrent
https://media.nb.envai.win        → Jellyfin
https://adminer.nb.envai.win      → Adminer
https://n8n.nb.envai.win          → n8n
```
### ⚠️ Проблемы и решения Reverse Proxy

![Proplems](./images/ProblemsProxy.png)

## 4. Решённые проблемы с приложениями

### 🟢 Nextcloud — ошибка 500 (финальная причина)

- Симптом: При открытии https://nextcloud.nb.envai.win/login возвращается пустой HTTP 500 без записей в nextcloud.log.

- Реальная причина: Параметр forwarded_for_headers в config.php был записан как строка "HTTP_X_FORWARDED_FOR" вместо массива ["HTTP_X_FORWARDED_FOR"].

- Механизм сбоя:
  - Метод getRemoteAddress() в Nextcloud вызывает array_reverse() на строке → TypeError
  - Эта функция вызывается внутри обработчика страницы ошибок (printExceptionErrorPage)
  - Получается "двойной сбой": первая ошибка гасилась, при попытке красиво её показать вылетала вторая
  - Сервер отдавал пустой 500 без единой подсказки в логах

- Решение:

```bash
# Открыть config.php
nano /var/lib/nextcloud/config/config.php

# Найти строку:
'forwarded_for_headers' => 'HTTP_X_FORWARDED_FOR',

# Исправить на массив:
'forwarded_for_headers' => 
array (
  0 => 'HTTP_X_FORWARDED_FOR',
),

# Перезапустить
docker restart nextcloud
```

- Дополнительные обязательные настройки Nextcloud для работы за Reverse Proxy:

```php
'trusted_domains' => 
array (
  0 => 'localhost',
  1 => '100.110.87.149',         # NetBird IP HS
  2 => 'nextcloud.nb.envai.win', # Публичный домен
),
'trusted_proxies' => 
array (
  0 => '100.64.0.0/16',          # NetBird mesh
  1 => '172.16.0.0/12',          # Docker networks
),
'overwriteprotocol' => 'https',
'overwritehost' => 'nextcloud.nb.envai.win',
'overwrite.cli.url' => 'https://nextcloud.nb.envai.win',
'force_ssl' => false,            # TLS терминирует NetBird proxy
```
### 🟢 Jellyfin — видео не воспроизводилось

- Симптом: FFmpeg exited with code 218 / 187.
- Причины: 
  - GPU не был проброшен в контейнер (/dev/dri/ пустой внутри)
  - Jellyfin пытался кодировать в AV1, который RDNA 2 не поддерживает аппаратно

- Решение:
```yaml
# В docker-compose.yml для Jellyfin:
devices:
  - /dev/dri/renderD128:/dev/dri/renderD128
  - /dev/dri/card0:/dev/dri/card0
group_add:
  - "44"   # video
  - "991"  # render
```
В админке Jellyfin → Playback → Transcoding:

- Hardware acceleration: VAAPI (не Intel QuickSync!)
- ❌ Отключить: Allow encoding in AV1 format
- ❌ Отключить: Enable VPP Tone mapping (Intel-only)
- ✅ Включить: H264, HEVC, VP9, HEVC 10bit

### 🟢 qBittorrent — падение через прокси

- Симптом: В логах unknown content type: "application/json", OPTIONS method not allowed.
- Причина: Встроенные защиты qBittorrent (CSRF, Clickjacking) блокировали запросы от reverse proxy.
- Решение: Остановить контейнер, добавить в /home/lorydari/docker/qBittorrent/config/qBittorrent.conf:

```ini
[Preferences]
WebUI\CSRFProtection=false
WebUI\ClickjackingProtection=false
WebUI\SecureCookie=false
WebUI\HostHeaderValidation=true
WebUI\ServerDomains=*
```
- В NetBird Reverse Proxy для qBittorrent включить:
  - ✅ Pass Host Header = ON
  - ✅ Rewrite Redirects = ON
  - ✅ Password authentication (второй слой защиты)

## 🎯 Итоговая архитектура

```
[ИНТЕРНЕТ]
    │
    ▼
[RSB: 155.212.223.132]
┌──────────────────────────────────────────────────────────┐
│  Traefik (:80, :443)                                      │
│    ↓ TLS passthrough для *.nb.envai.win                   │
│  netbird-reverse-proxy                                    │
│    → TLS-терминация (Let's Encrypt)                       │
│    → WireGuard туннель к HS                               │
│  netbird-server (Management + Signal)                     │
│  netbird-dashboard (Web UI)                               │
└──────────────────────────────────────────────────────────┘
                    │ WireGuard (зашифровано)
                    ▼
[HS за NAT: 100.64.x.x]
┌──────────────────────────────────────────────────────────┐
│  NetBird agent (WireGuard peer)                           │
│  Docker контейнеры:                                       │
│    - Nextcloud        :49880 → nextcloud.nb.envai.win    │
│    - Vaultwarden      :49080 → vault.nb.envai.win        │
│    - Jellyfin         :8096  → media.nb.envai.win        │
│    - qBittorrent      :42080 → qbittorrent.nb.envai.win  │
│    - n8n              :15678 → n8n.nb.envai.win          │
│    - Adminer          :18080 → adminer.nb.envai.win      │
│    - Postgres         (только docker-сеть)                │
└──────────────────────────────────────────────────────────┘
```

## 🔒 Безопасность

- Все сервисы недоступны из публичного интернета напрямую (HS за NAT)
- NetBird-Only Access включен — доступ только для авторизованных пиров
- Двойная аутентификация: NetBird Password + пароль приложения
- WireGuard-шифрование между RSB и HS (ChaCha20-Poly1305)
- TLS-терминация на RSB с автоматическими Let's Encrypt сертификатами
- Cloudflare не видит трафик (DNS only — серое облако)