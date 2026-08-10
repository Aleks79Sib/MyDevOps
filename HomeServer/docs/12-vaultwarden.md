# 🔐 Vaultwarden — менеджер паролей

---

## 1. Настройка PostgreSQL

```bash
# Подключиться к PostgreSQL через Docker
docker exec -it postgres psql -U user -d db
```

Выполнить SQL:

```sql
CREATE USER vaultwarden WITH PASSWORD 'надёжный_пароль';
GRANT CONNECT ON DATABASE vault TO vaultwarden;
GRANT ALL PRIVILEGES ON DATABASE vault TO vaultwarden;

-- Переключиться на БД vault
\c vault

GRANT ALL PRIVILEGES ON SCHEMA public TO vaultwarden;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO vaultwarden;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO vaultwarden;
```

---

## 2. Добавить Vaultwarden в Cloudflare Tunnel

Добавить запись в `~/.cloudflared/config.yml`:

```yaml
- hostname: vaultwarden.YOUR_DOMAIN.com
  service: http://127.0.0.1:49080
  originRequest:
    httpHostHeader: vaultwarden.YOUR_DOMAIN.com
```

```bash
systemctl restart cloudflared
```

---

## 3. Добавить Vaultwarden в docker-compose.yml

Добавить в `~/docker/server/docker-compose.yml`:

```yml
vaultwarden:
  image: vaultwarden/server:latest
  container_name: vaultwarden
  restart: unless-stopped
  environment:
    - DOMAIN=https://vaultwarden.YOUR_DOMAIN.com
    - WEBSOCKET_ENABLED=true
    - SIGNUPS_ALLOWED=false
    - INVITATIONS_ALLOWED=false
    - ADMIN_TOKEN=${VW_ADMIN_TOKEN}
    - ROCKET_PORT=8080
    - DATABASE_URL=${VW_DATABASE_URL}
  volumes:
    - /data/vaultwarden:/data
  depends_on:
    - postgres
  ports:
    - "127.0.0.1:49080:8080"
```

Добавить в `.env`:

```ini
VW_ADMIN_TOKEN=сгенерировать_ключ
VW_DATABASE_URL=postgres://vaultwarden:пароль@postgres:5432/vault
```

```bash
docker-compose down
docker-compose up -d
```

---

## 4. Первоначальная настройка

1. Открыть `https://vaultwarden.YOUR_DOMAIN.com`
2. Зарегистрировать первый аккаунт
3. Сразу отключить регистрацию (`SIGNUPS_ALLOWED=false`)
4. Настроить `/admin` через ADMIN_TOKEN

---

## 5. Интеграция с n8n

В n8n: **Credentials → Generic → Secrets from Vaultwarden**

Перенести все API-ключи (OpenAI, Gemini, Telegram и т.д.) в Vaultwarden.
