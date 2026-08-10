# 🤖 OpenAI Proxy — свой API-шлюз

---

## 1. О проекте

OpenAI Proxy — это прокси-сервер, который позволяет использовать OpenAI API через свой домен.
- Поддержка OpenAI и Gemini
- Автоматический запуск через systemd
- Nginx с HTTPS на порту 8443

---

## 2. Установка на VPS (RSB)

### 2.1. Установить Nginx

```bash
sudo apt update
sudo apt install nginx -y
```

### 2.2. Создать рабочую директорию

```bash
sudo mkdir -p /opt/openai-proxy
sudo chown YOUR_USER:YOUR_USER /opt/openai-proxy
cd /opt/openai-proxy
```

### 2.3. Создать server.js и models.json

```bash
nano /opt/openai-proxy/server.js
nano /opt/openai-proxy/models.json
```

### 2.4. Установить зависимости

```bash
npm init -y
npm install express axios dotenv
```

### 2.5. Создать .env

```bash
nano /opt/openai-proxy/.env
```

```ini
PORT=3000
OPENAI_API_KEY=sk-your-openai-key
PROXY_KEYS=your-proxy-keys
```

```bash
sudo chown YOUR_USER:YOUR_USER /opt/openai-proxy/.env
chmod 600 /opt/openai-proxy/.env
```

---

## 3. Настройка systemd

```bash
sudo nano /etc/systemd/system/openai-proxy.service
```

```ini
[Unit]
Description=OpenAI Proxy
After=network.target

[Service]
Type=simple
User=YOUR_USER
WorkingDirectory=/opt/openai-proxy
ExecStart=/usr/bin/node /opt/openai-proxy/server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now openai-proxy.service

# Проверить
sudo systemctl status openai-proxy
journalctl -u openai-proxy -f
```

---

## 4. Nginx + HTTPS

### 4.1. Конфиг Nginx

```bash
sudo nano /etc/nginx/sites-available/api-ssl
```

```nginx
server {
    listen 8443 ssl;
    server_name api.YOUR_DOMAIN.com;

    ssl_certificate /etc/letsencrypt/live/api.YOUR_DOMAIN.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.YOUR_DOMAIN.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    location /openai/v1/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Authorization $http_authorization;
        proxy_pass_header Authorization;
        proxy_http_version 1.1;
        proxy_set_header Connection '';
        proxy_connect_timeout 60s;
        proxy_send_timeout 120s;
        proxy_read_timeout 120s;
    }

    location / {
        return 404;
    }
}
```

```bash
sudo ln -sf /etc/nginx/sites-available/api-ssl /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### 4.2. Получить SSL-сертификат (Certbot)

```bash
sudo apt install certbot -y
sudo systemctl stop nginx
sudo certbot certonly --standalone -d api.YOUR_DOMAIN.com
sudo systemctl start nginx
```

### 4.3. Автообновление сертификата

👉 Скрипт обновления: [`../scripts/renew-cert.sh`](../scripts/renew-cert.sh)

```bash
sudo cp ../scripts/renew-cert.sh /home/YOUR_USER/renew-cert.sh
chmod +x /home/YOUR_USER/renew-cert.sh

# Добавить в crontab (запуск 1-го числа каждого месяца)
sudo crontab -e
# Добавить строку:
0 2 1 * * /home/YOUR_USER/renew-cert.sh
```

---

## 5. Полезные команды

```bash
# Статус прокси
sudo systemctl status openai-proxy

# Логи
journalctl -u openai-proxy -f

# Перезапуск
sudo systemctl restart openai-proxy

# Проверить Nginx
sudo nginx -t
sudo systemctl status nginx

# Тест API
curl -s https://api.YOUR_DOMAIN.com/openai/v1/models
```
