# 📁 Samba — файловое хранилище в локальной сети

---

## 1. Установка Samba

```bash
sudo apt update && sudo apt install samba -y
```

---

## 2. Проверка и настройка прав на папку

```bash
# Проверить права на папку с файлами
ls -ld /data/samba

# Выставить правильные права (владелец — ваш пользователь)
sudo chown -R YOUR_USER:YOUR_USER /data/samba
sudo chmod -R 775 /data/samba
```

> Рекомендуемые права: `775` — владелец и группа могут читать/писать, остальные только читать.

### Если пользователя нет — создать

```bash
id YOUR_USER
# Если нет:
sudo useradd -M -s /usr/sbin/nologin YOUR_USER
```

---

## 3. Конфигурация Samba

Пример конфигурационного файла:

👉 [`../scripts/smb.conf`](../scripts/smb.conf)

```bash
# Отредактировать конфиг
sudo nano /etc/samba/smb.conf
```

**Основные параметры:**

| Параметр | Значение | Описание |
|----------|----------|----------|
| `workgroup` | `WORKGROUP` | Рабочая группа (как в Windows) |
| `security` | `user` | Вход по логину/паролю |
| `valid users` | `YOUR_USER` | Только этот пользователь имеет доступ |
| `writable` | `yes` | Разрешить запись |
| `guest ok` | `no` | Гости не допускаются |

### Установить SMB-пароль для пользователя

```bash
sudo smbpasswd -a YOUR_USER
```

---

## 4. Запуск и проверка

```bash
# Разрешить Samba в фаерволе
sudo ufw allow from 192.168.1.0/24 to any port 445 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 139 proto tcp

# Перезапустить сервисы
sudo systemctl restart smbd nmbd

# Проверить статус
sudo systemctl status smbd
```

---

## 5. Подключение с клиентов

```bash
# Проверить доступные шары на сервере
sudo smbstatus --shares
```

| ОС | Команда подключения |
|----|-------------------|
| **Windows** | `\\IP_СЕРВЕРА\shared` |
| **macOS** | `smb://IP_СЕРВЕРА/shared` |
| **Linux** | `smbclient //IP_СЕРВЕРА/shared -U YOUR_USER` |

---

## 6. Полезные команды

```bash
# Посмотреть активные подключения
sudo smbstatus

# Перезагрузить конфигурацию без перезапуска
sudo smbcontrol smbd reload-config

# Проверить конфиг на ошибки
testparm

# Посмотреть логи Samba
sudo tail -f /var/log/samba/log.smbd

# Изменить пароль пользователя Samba
sudo smbpasswd YOUR_USER
```

---

## 7. Шпаргалка

| Сценарий | Команда |
|----------|---------|
| Установить Samba | `sudo apt install samba -y` |
| Задать пароль | `sudo smbpasswd -a YOUR_USER` |
| Перезапустить | `sudo systemctl restart smbd nmbd` |
| Проверить конфиг | `testparm` |
| Проверить подключения | `sudo smbstatus` |
| Открыть порты в UFW | `sudo ufw allow samba` |
| Логи Samba | `sudo tail -f /var/log/samba/log.smbd` |
