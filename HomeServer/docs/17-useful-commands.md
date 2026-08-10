# 🛠 Полезные команды

---

## 1. Docker

```bash
# Перезапустить все сервисы
docker-compose restart

# Обновить все образы и перезапустить
docker-compose pull
docker-compose up -d

# Экспорт workflows из n8n
docker exec -u node n8n n8n export:workflow --all --output=/home/node/workflows.json
docker cp n8n:/home/node/workflows.json ~/workflows.json

# Экспорт credentials из n8n
docker exec -u node -e N8N_ENCRYPTION_KEY="YOUR_PASSWORD" n8n n8n export:credentials --all --decrypted --output=/home/node/credentials.json
docker cp n8n:/home/node/credentials.json ~/credentials.json
```

---

## 2. Система

```bash
# Перезагрузка
sudo reboot

# Выключение
sudo poweroff

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Очистка
sudo apt autoremove -y
sudo apt clean
```

---

## 3. Работа с файлами

```bash
# Копирование с компьютера на сервер
rsync -avhP ~/my-files/ user@server:/data/share/

# Чтобы убедиться, что будет скопировано, добавьте -n (пробный прогон):
rsync -avn --ignore-existing /исходная/папка/ /папка/назначения/

# Копирование Вы не хотите вручную сверять списки файлов — и правильно, для этого есть rsync. 
# Он сам сравнит содержимое папок и сделает всё автоматически.
rsync -av --ignore-existing /исходная/папка/ /папка/назначения/
# rsync проходит по всем файлам в исходной папке.
# Для каждого файла проверяет: есть ли такой же файл (с тем же именем) в папке назначения?
# Если есть — пропускает (ничего не перезаписывает).
# Если нет — копирует.

# Tогда просто --ignore-existing может пропустить битый файл, потому что он существует. Для этого случая используйте докачку:
rsync -av --partial --append-verify /исходная/папка/ /папка/назначения/

# Добавьте ключ -u (update) — тогда rsync скопирует только те файлы, которых нет или которые в источнике новее (по дате изменения):
rsync -avu /исходная/папка/ /папка/назначения/

# Копирование с сервера на компьютер
rsync -avhP user@server:/data/share/ ~/my-files/

# Архивация
tar -czf backup.tar.gz /data
tar -xzf backup.tar.gz -C /restore

# Поиск больших файлов
du -sh /* 2>/dev/null | sort -rh | head -10
```

---

## 4. Логи

```bash
# Логи Docker-сервиса
docker-compose logs -f [service_name]

# Все логи системы
sudo journalctl -f

# Логи за последний час
sudo journalctl --since "1 hour ago"

# Логи аутентификации
sudo tail -f /var/log/auth.log

# Логи SSH
sudo journalctl -u ssh -f

# Очистить логи systemd за 7 дней
sudo journalctl --vacuum-time=7d
```

---

## 5. Сеть

```bash
# Какие порты слушаются
sudo ss -tlnp

# Проверить IP-адреса
ip a

# Внешний IP
curl -s ifconfig.me

# Проверить DNS
nslookup google.com
```

---

## 6. SSH

```bash
# Настройка config для удобного подключения
nano ~/.ssh/config
```

Пример конфига:

```text
Host homeserver
    HostName 192.168.1.100
    Port 2222
    User admin
    IdentityFile ~/.ssh/id_ed25519
```

```bash
# Подключаться теперь можно так:
ssh homeserver
```

---

## 7. Генерация паролей

```bash
# Надёжный пароль / ключ (32 байта, Base64)
openssl rand -base64 32

# HEX (64 символа)
openssl rand -hex 32

# Короткий пароль (16 байт)
openssl rand -base64 16
```
