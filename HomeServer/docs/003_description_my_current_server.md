# 📘 Расширенное резюме чата: Сборка и настройка домашнего сервера

## 🎯 Цель проекта

Создание мощного домашнего сервера для запуска множества сервисов: Nextcloud, автоматизация (n8n), менеджер паролей (Vaultwarden), медиа-сервер (Jellyfin), умный дом (Home Assistant), торрент-клиент (qBittorrent), мониторинг (Uptime Kuma) и в перспективе — локальный ИИ-ассистент на RTX 3090.

---

## 🖥️ 1. Железо: финальная конфигурация

### Основные компоненты

| Компонент | Модель | Характеристики |
|-----------|--------|----------------|
| **Процессор** | AMD Ryzen 7 7700X (OEM) | 8 ядер / 16 потоков, сокет AM5 |
| **Материнская плата** | MSI PRO B650-P WIFI | AM5, B650, DDR5, Wi-Fi 6E, Bluetooth 5.2 |
| **ОЗУ** | 32 ГБ (2×16) DDR5 6000 МГц CL30 | Patriot Viper Venom / ADATA XPG Lancer Blade |
| **Кулер CPU** | Thermalright Peerless Assassin 120 | Двухбашенный, 2 вентилятора, 6 тепловых трубок |
| **Системный SSD** | Kingston KC3000 1TB NVMe PCIe 4.0 | Для ОС, БД, Docker |
| **Накопитель данных** | 2 × Seagate IronWolf 4TB (ST4000VN006) | RAID 1 (зеркало), смонтирован в `/storage` |
| **Блок питания** | Thermaltake Toughpower GT 1000W | ATX 3.1, 80 PLUS Gold, модульный, 12V-2x6 |
| **Корпус** | DeepCool CG580 4F V2 | Midi-Tower, 2 отсека для 3.5" HDD |
| **Видеокарта** | RTX 3090 24GB (в планах) | Для ИИ-задач, турбинное охлаждение |

### Разметка дисков

| Диск | Размер | Назначение | Точка монтирования |
|------|--------|------------|-------------------|
| `/dev/nvme0n1` | 1 ТБ | ОС, /boot, swap, /, /var/lib/postgresql, /var/lib/docker | `/` и подкаталоги |
| `/dev/md0` (RAID 1) | 4 ТБ (полезных ~1.8 ТБ) | Пользовательские данные (Nextcloud, медиа, проекты, бэкапы) | `/storage` |

---

## 🐧 2. Программная экосистема

### Операционная система
- **Ubuntu Server 24.04 LTS** (ядро 7.0.0-27-generic)

### Ключевые установленные сервисы

| Сервис | Назначение | Способ запуска |
|--------|------------|----------------|
| **Nextcloud** | Личное облако (файлы, календари, контакты) | Docker |
| **PostgreSQL** | База данных для всех сервисов | Docker |
| **n8n** | Автоматизация и AI-воркфлоу | Docker |
| **Vaultwarden** | Менеджер паролей (Bitwarden-совместимый) | Docker |
| **Jellyfin** | Медиа-сервер (фильмы, сериалы) | Docker |
| **Home Assistant** | Умный дом | Docker (сетевой режим host) |
| **qBittorrent** | Торрент-клиент | Docker |
| **Uptime Kuma** | Мониторинг доступности сервисов | Docker |
| **Nginx Proxy Manager** | Обратный прокси и SSL-сертификаты | Docker |
| **NetBird** | VPN и обратный прокси для внешнего доступа | Клиент + сервер (VPS) |
| **Redis** | Кэширование для Nextcloud | Docker |
| **Portainer** | Управление Docker-контейнерами | Docker |
| **Samba** | Файловый доступ по локальной сети | Прямая установка |

### Сеть и безопасность
- **SSH**: порт изменён на 2222
- **UFW**: брандмауэр
- **Fail2Ban**: защита от брутфорса
- **Cloudflare Tunnel**: альтернативный способ внешнего доступа

---

## 🚨 3. Главная проблема: Nextcloud Error 500

### Описание проблемы
После смены домена с `nextcloud.envai.win` на `nextcloud.nb.envai.win` и перехода с Cloudflare/SSH-туннеля на NetBird, Nextcloud перестал открываться. При попытке зайти на `/login` выдавалась ошибка HTTP 500 без каких-либо следов в логах.

### Хронология поиска решения

#### Этап 1: Редиректы и overwritehost
**Проблема**: Nextcloud редиректил на старый домен.
**Решение**: Удаление параметра `'overwritehost' => 'nextcloud.envai.win'` из `config.php` и замена `overwrite.cli.url` на новый домен.

#### Этап 2: Синтаксическая ошибка в config.php
**Проблема**: В массиве `trusted_proxies` была пропущена запятая.
**Ошибка**: `PHP Parse error: syntax error, unexpected integer "7", expecting ")" in /var/www/html/config/config.php on line 71`
**Решение**: Добавление запятой после `6 => '172.22.0.1/16'`.

#### Этап 3: Безуспешные попытки
Были перепробованы:
- Очистка кэша (`rm -rf /var/www/html/data/cache`)
- Обновление базы данных (`occ db:add-missing-indices`)
- Ремонт (`occ maintenance:repair`)
- Включение `debug` и `loglevel 0`
- Отключение подозрительных приложений (`integration_openai`, `assistant`, `context_chat` и др.)
- Проверка прав на папки (`chown -R www-data:www-data`)

**Результат**: Ничего не помогло. Ошибка 500 оставалась, в логах не было никаких следов.

#### 🔥 Этап 4: Ключевое открытие (от пользователя)

**Причина**: Параметр `forwarded_for_headers` был записан как строка, а не как массив.

**Было**:
```php
'forwarded_for_headers' => 'HTTP_X_FORWARDED_FOR',
```

**Должно быть**:
```php
'forwarded_for_headers' => ['HTTP_X_FORWARDED_FOR'],
```

**Почему это вызывало Error 500**:
- `getRemoteAddress()` вызывает `array_reverse()` на этом параметре.
- Если параметр — строка, `array_reverse()` получает строку вместо массива и падает с `TypeError`.
- Ошибка возникает внутри обработчика ошибок (`printExceptionErrorPage`), из-за чего не выводится ни одна нормальная ошибка, а сервер отдаёт пустой HTTP 500.
- В логах Nextcloud нет записей, потому что ошибка происходит на уровне PHP до того, как Nextcloud успевает записать что-то в свой лог.

---

## 🛠️ 4. Настройка NetBird

### Установка на VPS (RSB)

```bash
curl -fsSL https://github.com/netbirdio/netbird/releases/latest/download/getting-started.sh | bash
```

**Выбор в процессе установки**:
- Reverse proxy: `[0] Traefik`
- Включить NetBird Proxy: `y`

**DNS-записи**:
- A: `netbird.ваш-домен` → IP_VPS
- CNAME: `*.netbird.ваш-домен` → `netbird.ваш-домен`

### Установка клиента на домашнем сервере (HS)

```bash
curl -fsSL https://pkgs.netbird.io/install.sh | sh
netbird up --setup-key YOUR_SETUP_KEY
```

**Конфиг клиента**: `/etc/netbird/config.yaml`
```yaml
management_url: "https://ваш-домен.netbird"
```

**Автозапуск**:
```bash
sudo netbird service uninstall
sudo netbird service install
sudo netbird service start
```

### Настройка Reverse Proxy для поддоменов

1. В панели NetBird: **Reverse Proxy → Custom Domains → Add Domain**
2. Добавить базовый домен (например, `proxy.ваш-домен`)
3. DNS-верификация: CNAME `*.proxy.ваш-домен` → `netbird.ваш-домен`
4. **Reverse Proxy → Services → Add Service**:
   - Subdomain: `nextcloud`
   - Domain: `proxy.ваш-домен`
   - Target: `http://IP_сервера:28080` (или `http://nextcloud:80`)

Доступ по адресу: `https://nextcloud.proxy.ваш-домен`

---

## 📚 5. Дополнительные сервисы

### Читалки для книг

**В Nextcloud** (установка через магазин приложений):
- **Reader** (`files_reader`) — EPUB, PDF, CBR, CBZ
- **EPUB Viewer** (`epubviewer`) — EPUB, PDF, CBR, CBZ, закладки, ночной режим

**В Jellyfin**:
- Плагин **Bookshelf** для хранения книг
- Клиент **JellyBook** (Android/iOS) для чтения
- Плагин **KOFin** для синхронизации с KOReader

### Рекомендуемые к установке сервисы

| Сервис | Назначение | Приоритет |
|--------|------------|-----------|
| **Uptime Kuma** | Мониторинг доступности сервисов | 🔴 Высокий |
| **Redis** | Кэширование для Nextcloud | 🔴 Высокий |
| **Kavita** | Читалка книг и комиксов | 🟡 Средний |
| **Authelia** | Единая точка входа с 2FA | 🟢 Низкий (сложная настройка) |

---

## 📝 6. Итоговый список полезных команд

### Работа с Docker
```bash
# Запуск и остановка контейнеров
docker compose up -d
docker compose down
docker compose restart nextcloud

# Просмотр логов
docker logs nextcloud --tail 50
docker exec -it nextcloud tail -100 /var/www/html/data/nextcloud.log

# Выполнение команд внутри контейнера
docker exec -it nextcloud php /var/www/html/occ status
docker exec -it nextcloud php /var/www/html/occ config:system:get overwrite.cli.url
```

### Настройка Nextcloud через occ
```bash
# Управление параметрами
docker exec -it nextcloud php /var/www/html/occ config:system:set overwrite.cli.url --value="https://nextcloud.nb.envai.win"
docker exec -it nextcloud php /var/www/html/occ config:system:delete overwritehost
docker exec -it nextcloud php /var/www/html/occ config:system:set trusted_domains 0 --value="nextcloud.nb.envai.win"

# Управление приложениями
docker exec -it nextcloud php /var/www/html/occ app:disable --all
docker exec -it nextcloud php /var/www/html/occ app:enable files dav provisioning_api settings

# Обслуживание
docker exec -it nextcloud php /var/www/html/occ maintenance:repair
docker exec -it nextcloud php /var/www/html/occ db:add-missing-indices
```

### Диагностика
```bash
# Проверка синтаксиса config.php
docker exec -it nextcloud php -l /var/www/html/config/config.php

# Проверка прав доступа
docker exec -it nextcloud ls -la /var/www/html/data/
docker exec -it nextcloud chown -R www-data:www-data /var/www/html/data

# Включение отладки
# Добавить в config.php:
'debug' => true,
'loglevel' => 0,

# Принудительный вывод ошибок PHP (в начало config.php):
ini_set('display_errors', 1);
```

---

## 💡 7. Ключевые выводы

### ❗ Главный урок
Ошибка 500 без следов в логах часто возникает из-за того, что ошибка происходит внутри обработчика ошибок. В случае с Nextcloud это была ошибка Type Error из-за параметра `forwarded_for_headers`, который должен быть массивом, а не строкой.

### ✅ Что делать в аналогичной ситуации
1. Проверить `overwritehost` и `overwrite.cli.url`
2. Проверить синтаксис `config.php` (`php -l`)
3. Включить `debug` и `loglevel 0`
4. Проверить параметр `forwarded_for_headers` (должен быть массивом)
5. Отключить подозрительные приложения
6. Проверить логи Apache: `/var/log/apache2/error.log`

### ⚙️ Рабочая конфигурация NetBird + Nextcloud
- NetBird обрабатывает внешний трафик на VPS
- Клиент на HS подключается через setup-key
- Reverse Proxy NetBird пробрасывает запросы на внутренние IP/порты
- `config.php` содержит правильные `trusted_proxies`, `overwrite.cli.url`, `trusted_domains` и `forwarded_for_headers` в виде массива

---

## 🎯 8. Планы на будущее

- Установка RTX 3090 для локального ИИ-ассистента
- Запуск Ollama для работы с LLM-моделями
- Расширение медиатеки в Jellyfin
- Интеграция Authelia для единой аутентификации

---

## 🙏 Благодарность

Особая благодарность пользователю, который нашёл корень проблемы с `forwarded_for_headers` — это был сложный и неочевидный баг, требующий глубокого понимания внутреннего устройства Nextcloud и PHP-обработки ошибок. Спасибо за терпение и настойчивость в решении проблемы.