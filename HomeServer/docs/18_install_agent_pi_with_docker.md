# Pi Coding Agent — Домашний сервер

Безопасное развёртывание Pi с MCP-серверами в Docker на Linux-сервере.

## Быстрый старт

```bash
# 1. Копируем на сервер
scp -r /Users/leik.van-23/AGENTS/pi_demo/home-server user@server:~/

# 2. Заходим на сервер
ssh user@server
cd ~/home-server

# 3. Создаём .env из шаблона
cp .env.example .env
nano .env   # вписать API-ключи

# 4. Создаём папку для проекта
mkdir workspace

# 5. Собираем и запускаем
docker compose build --no-cache
docker compose up -d

# 6. Подключаемся
docker compose exec -it pi bash
cd /workspace
pi

# Или сразу:
docker compose run --rm pi -p "Привет"
```

## Доступные модели

| Модель | Провайдер | Переменная |
|--------|-----------|------------|
| Claude Sonnet/Haiku/Opus | Anthropic | `ANTHROPIC_API_KEY` |
| **DeepSeek V4 Flash** (1M контекст) | DeepSeek | `DEEPSEEK_API_KEY` |
| **DeepSeek V4 Pro** (1M контекст) | DeepSeek | `DEEPSEEK_API_KEY` |
| DeepSeek Chat (V3) | DeepSeek | `DEEPSEEK_API_KEY` |
| DeepSeek R1 | DeepSeek | `DEEPSEEK_API_KEY` |
| Qwen Plus / Max / Turbo | DashScope | `QWEN_API_KEY` |
| GPT-4o, GPT-4o-mini | OpenAI | `OPENAI_API_KEY` |

## Переключение модели

```
/model deepseek-v4-flash
/model deepseek-v4-pro
/model deepseek-chat
/model deepseek-reasoner
/model qwen-plus
/model claude-sonnet-4-20250514
```

## Перенос сессий с macOS

Все твои сессии скопированы в папку `sessions/` на сервере.
Они смонтированы в контейнер и доступны Pi.

**Нюанс:** Сессии привязаны к старому пути (`/Users/.../AGENTS/pi_demo`).
На сервере cwd — `/workspace`, поэтому в `/resume` они могут не появиться сразу.
Но их можно открыть по ID:

```bash
# Список всех сессий (покажет даже из других папок)
pi -r

# Или открыть конкретную
pi --session 019ea8d3-82e7-7910-89f4-79f0c40f83db
```

Если хочешь, чтобы сессии отображались в `/resume` как родные —
переименуй папку на сервере:

```bash
# На сервере, внутри home-server/
mv sessions/--Users-leik.van-23-AGENTS-pi_demo-- sessions/--workspace--
```

После этого `/resume` покажет их как местные.

## Подключение через Cloudflare Tunnel

Туннель управляется отдельно.

**Ingress в config.yml:**

```yaml
ingress:
  # Pi Agent — SSH
  - hostname: pi.envai.win
    service: ssh://localhost:2222
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      httpHostHeader: pi.envai.win
      originServerName: pi.envai.win

  # Playwright MCP (опционально — только с Cloudflare Access!)
  - hostname: mcp.envai.win
    service: http://localhost:3100
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
```

**Важно:** Playwright через туннель — только с Cloudflare Access (логин/OAuth).

---

## Полная карта безопасности

```
┌──────────────────────────────────────────────────────┐
│                   ХОСТ (твой сервер)                  │
│                                                       │
│  ┌──────────────────────────────────────────────┐    │
│  │  Контейнер: pi-agent                          │    │
│  │                                               │    │
│  │  ● Пользователь: agent_pi (не root)          │ 🟢 │
│  │  ● Файловая система: read-only               │ 🟢 │
│  │  ● Capabilities: ALL отозваны                 │ 🟢 │
│  │  ● no-new-privileges: true                    │ 🟢 │
│  │  ● Видит только ./workspace                   │ 🟢 │
│  │  ● Docker.sock — НЕ смонтирован              │ 🟢 │
│  │  ● /tmp, .cache, .npm — tmpfs (в памяти)     │ 🟢 │
│  │  ● Лимит памяти: 2G, CPU: 2 ядра             │ 🟢 │
│  │  ● Healthcheck: каждые 30с                    │ 🟢 │
│  │                                               │    │
│  │  ┌──────────────────────────────────────┐     │    │
│  │  │  Playwright MCP (Chromium)           │     │    │
│  │  │  ● Порт 3100 — только pi-net         │ 🟢  │    │
│  │  │  ● Память: 4G, CPU: 4 ядра           │ 🟢  │    │
│  │  │  ● Healthcheck: TCP check             │ 🟢  │    │
│  │  │  ● nofile/nproc ulimits               │ 🟢  │    │
│  │  └──────────────────────────────────────┘     │    │
│  └──────────────────────────────────────────────┘    │
│                                                       │
│  Volumes:                                             │
│  ● pi-agent-home — сессии и настройки                │ 🟡 │
│  ● ./workspace — проект                              │ 🟢 │
│  ● tmpfs — /tmp, кеши                                │ 🟢 │
│                                                       │
│  Сеть:                                                │
│  ● Изолированная pi-net                               │ 🟢 │
│  ● Выход в интернет: только для Playwright            │ 🟢 │
│                                                       │
│  Версии:                                              │
│  ● Pi: @0.79.3                                        │ 🟢 │
│  ● pi-mcp-adapter: @2.10.0                            │ 🟢 │
│  ● nightmare-mcp: не зафиксирован (latest)            │ 🟡 │
└──────────────────────────────────────────────────────┘

Оценка: 8.5/10 → 9/10
```

---

## Сводка мер безопасности

| Категория | Мера | Статус |
|-----------|------|--------|
| **Пользователь** | `agent_pi` (не root) | 🟢 |
| **ФС контейнера** | `read_only: true` | 🟢 |
| **tmpfs** | /tmp, .cache, .npm в памяти | 🟢 |
| **Кеши XDG** | Перенаправлены в /tmp | 🟢 |
| **Capabilities** | `cap_drop: ALL` | 🟢 |
| **Privilege escalation** | `no-new-privileges` | 🟢 |
| **Docker.sock** | Не смонтирован | 🟢 |
| **Порты** | Не опубликованы наружу | 🟢 |
| **Сеть** | Изолированная `pi-net` | 🟢 |
| **Лимиты памяти** | Pi: 2G, Playwright: 4G | 🟢 |
| **Лимиты CPU** | Pi: 2 ядра, Playwright: 4 ядра | 🟢 |
| **Healthcheck** | Оба контейнера | 🟢 |
| **Версии пакетов** | Pi и adapter — фиксированы | 🟢 |
| **npm cache** | Очищен в образе | 🟢 |
| **--ignore-scripts** | npm-скрипты отключены | 🟢 |
| **stop_grace_period** | 30s на корректное завершение | 🟢 |
| **ulimits** | Playwright: nofile/nproc | 🟢 |

## Что остаётся на тебе

- API-ключи в `.env` — не давать никому доступ к этому файлу
- Сессии в volume `pi-agent-home` — могут содержать ключи
- Playwright — если открываешь через туннель, настрой Cloudflare Access
- Версия `playwright-mcp@latest` — можно зафиксировать, если хочешь

## Может ли Pi навредить?

| Действие | Возможно? |
|----------|-----------|
| Прочитать `/etc/shadow` хоста | ❌ Нет, ФС изолирована |
| Записать файл вне проекта | ❌ Только в `/workspace` |
| Удалить системные файлы | ❌ Rootfs read-only |
| Запустить Docker | ❌ Нет docker.sock |
| Прочитать твои API-ключи | 🟡 Из сессий на volume да, из .env нет |
| Выйти в интернет | ✅ Через Playwright (нужно для работы) |
| Сделать скриншот сайта | ✅ Для этого и ставится |
