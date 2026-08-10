# 🔄 Reverse Tunnel — доступ к HS через VPS

---

## 1. Установка на HS

```bash
sudo apt install nmap -y

# Настроить права для nmap
sudo setcap cap_net_raw+ep /usr/bin/nmap

# Проверить
getcap /usr/bin/nmap
# Должно быть: /usr/bin/nmap = cap_net_raw+ep
```

---

## 2. Создать скрипт туннеля

```bash
mkdir -p ~/scripts
touch ~/scripts/rsb-tunnel.sh
chmod +x ~/scripts/rsb-tunnel.sh
nano ~/scripts/rsb-tunnel.sh
```

Содержимое скрипта — SSH-туннель к VPS с авто-восстановлением.

---

## 3. Настройка systemd

```bash
sudo nano /etc/systemd/system/hs-to-rsb-tunnel.service
```

```ini
[Unit]
Description=Reverse SSH Tunnel from HS to RSB
After=network.target

[Service]
User=YOUR_USER
ExecStart=/home/YOUR_USER/scripts/rsb-tunnel.sh
Restart=always
RestartSec=15
StandardOutput=append:/var/log/tunnel.log
StandardError=append:/var/log/tunnel.log

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now hs-to-rsb-tunnel

# Проверить
sudo systemctl status hs-to-rsb-tunnel
sudo journalctl -u hs-to-rsb-tunnel -f
```

---

## 4. Подключение с VPS к HS

```bash
# На VPS (RSB):
ssh -p 2222 YOUR_USER@localhost
```

---

## 5. Полезные команды

```bash
# Статус туннеля
sudo systemctl status hs-to-rsb-tunnel

# Логи
sudo journalctl -u hs-to-rsb-tunnel -f

# Перезапустить
sudo systemctl restart hs-to-rsb-tunnel

# Остановить
sudo systemctl stop hs-to-rsb-tunnel
```
