# 🌐 Cloudflare Tunnel — доступ к серверу из интернета

---

## 1. Установка cloudflared

```bash
# Добавить GPG-ключ Cloudflare
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null

# Добавить репозиторий
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared jammy main" | sudo tee /etc/apt/sources.list.d/cloudflared.list

# Установить
sudo apt update
sudo apt install cloudflared -y

# Проверить
cloudflared --version
```

---

## 2. Авторизация и создание туннеля

```bash
# Авторизоваться в Cloudflare (откроется браузер)
cloudflared tunnel login

# Создать туннель
cloudflared tunnel create home-tunnel

# Покажет Tunnel ID — запомнить! (пример: 6ff42ae2-...)
cloudflared tunnel list
```

---

## 3. Конфигурация туннеля

Пример конфигурационного файла:

👉 [`../scripts/cloudflared-config.yml`](../scripts/cloudflared-config.yml)

```bash
# Создать папку
mkdir -p ~/.cloudflared

# Скопировать пример и отредактировать
nano ~/.cloudflared/config.yml
```

**Что нужно заменить в файле:**
- `YOUR_TUNNEL_ID` — на ID из шага 2 (`cloudflared tunnel list`)
- `YOUR_USER` — на вашего пользователя (например, `admin`)
- `YOUR_DOMAIN.com` — на ваш домен в Cloudflare

---

## 4. Настройка автозапуска (systemd)

```bash
sudo nano /etc/systemd/system/cloudflared.service
```

```ini
[Unit]
Description=Cloudflare Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=YOUR_USER
Environment=HOME=/home/YOUR_USER
ExecStart=/usr/bin/cloudflared --no-autoupdate --config /home/YOUR_USER/.cloudflared/config.yml tunnel run
Restart=always
RestartSec=5s
TimeoutStartSec=30s

[Install]
WantedBy=multi-user.target
```

```bash
# Выставить правильные права
sudo chown YOUR_USER:YOUR_USER ~/.cloudflared/config.yml
sudo chmod 644 ~/.cloudflared/config.yml
sudo chmod 600 ~/.cloudflared/*.json   # credentials — только для владельца

# Запустить и включить автозапуск
sudo systemctl daemon-reload
sudo systemctl enable --now cloudflared.service

# Проверить статус
sudo systemctl status cloudflared.service
```

---

## 5. Полезные команды

### Управление туннелем

```bash
# Статус туннеля
sudo systemctl status cloudflared.service

# Логи в реальном времени
sudo journalctl -u cloudflared.service -f

# Посмотреть последние N строк лога
sudo journalctl -u cloudflared.service -n 50 --no-pager

# Перезапустить туннель
sudo systemctl restart cloudflared.service

# Остановить туннель
sudo systemctl stop cloudflared.service

# Запустить туннель
sudo systemctl start cloudflared.service
```

### Диагностика

```bash
# Проверить, что туннель видит Cloudflare
cloudflared tunnel list

# Проверить DNS-записи (выполнить на любом компьютере)
nslookup n8n.YOUR_DOMAIN.com
# Должен вернуть IP Cloudflare: 104.16.x.x или CNAME на tunnel

# Проверить, какие порты слушает сервер (только локальные)
sudo ss -tlnp | grep -E '(5678|8080|6333|8096|8082)'
# Все порты должны быть на 127.0.0.1 — доступ только через Tunnel

# Тест соединения через туннель
curl -sI https://n8n.YOUR_DOMAIN.com
# Должен вернуть HTTP/2 200 или 302 (редирект)
```

### Обновление cloudflared

```bash
sudo apt update && sudo apt upgrade cloudflared -y
sudo systemctl restart cloudflared.service
```

---

## 6. Проверка безопасности

После настройки убедитесь, что сервисы **не торчат наружу** напрямую:

```bash
# Проверить, какие порты открыты на внешнем интерфейсе
sudo ss -tlnp | grep -E '0.0.0.0:|:::' | grep -v '127.0.0.1'
# Если ничего не вывелось — всё в порядке, порты только на 127.0.0.1
```

> Все сервисы должны слушать ТОЛЬКО на `127.0.0.1` (localhost).
> Доступ из интернета — только через Cloudflare Tunnel.

---

## 7. Шпаргалка

| Сценарий | Команда |
|----------|---------|
| Установить cloudflared | `sudo apt install cloudflared -y` |
| Создать туннель | `cloudflared tunnel create home-tunnel` |
| Запустить туннель | `sudo systemctl start cloudflared.service` |
| Посмотреть логи | `sudo journalctl -u cloudflared.service -f` |
| Перезапустить туннель | `sudo systemctl restart cloudflared.service` |
| Проверить статус | `sudo systemctl status cloudflared.service` |
| Проверить локальные порты | `sudo ss -tlnp \| grep -E '(5678\|8080\|6333)'` |
| Проверить доступность | `curl -sI https://n8n.ваш-домен.com` |
| Обновить cloudflared | `sudo apt upgrade cloudflared -y && sudo systemctl restart cloudflared` |
