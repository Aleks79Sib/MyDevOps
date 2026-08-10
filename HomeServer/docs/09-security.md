# 🔒 Безопасность и оптимизация сервера

---

## 1. Firewall (UFW)

```bash
# Разрешить SSH (порт 2222, если меняли)
sudo ufw allow 2222/tcp

# Разрешить HTTP/HTTPS
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp

# Включить фаервол
sudo ufw enable

# Проверить статус
sudo ufw status verbose
```

---

## 2. Fail2ban — защита от перебора паролей

```bash
# Создать локальный конфиг
sudo nano /etc/fail2ban/jail.local
```

```ini
[sshd]
enabled = true
port = 2222
maxretry = 3
bantime = 3600
```

```bash
# Перезапустить
sudo systemctl restart fail2ban

# Проверить статус
sudo systemctl status fail2ban
sudo fail2ban-client status sshd
```

---

## 3. Дополнительные меры безопасности

### Отключить root-вход по SSH

Уже настроено в `04-ssh-setup.md` с параметром `PermitRootLogin no`.

### Ограничить доступ по IP

```bash
# Разрешить доступ к серверу только из локальной сети
sudo ufw allow from 192.168.1.0/24

# Запретить всё остальное (если не нужен доступ извне)
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

### Мониторинг попыток входа

```bash
# Посмотреть неудачные попытки входа
sudo journalctl -u ssh -n 50 | grep "Failed password"

# Заблокировать IP вручную (если видите подозрительную активность)
sudo ufw deny from IP_АДРЕС
```

---

## 4. Полезные команды

```bash
# Статус фаервола
sudo ufw status numbered

# Удалить правило по номеру
sudo ufw delete 3

# Посмотреть забаненные IP в fail2ban
sudo fail2ban-client status sshd

# Разбанить IP
sudo fail2ban-client set sshd unbanip IP_АДРЕС

# Логи fail2ban
sudo tail -f /var/log/fail2ban.log
```

---

## 5. Шпаргалка

| Сценарий | Команда |
|----------|---------|
| Включить UFW | `sudo ufw enable` |
| Разрешить порт | `sudo ufw allow 2222/tcp` |
| Статус UFW | `sudo ufw status verbose` |
| Статус fail2ban | `sudo fail2ban-client status` |
| Статус SSH jail | `sudo fail2ban-client status sshd` |
| Разбанить IP | `sudo fail2ban-client set sshd unbanip 1.2.3.4` |
| Логи fail2ban | `sudo tail -f /var/log/fail2ban.log` |
