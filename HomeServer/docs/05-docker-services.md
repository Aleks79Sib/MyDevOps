# 🐳 Установка Docker, Docker Compose и управление контейнерами

---

## 1. Установка Docker и Docker Compose

```bash
# Установить Docker
sudo apt install -y docker.io docker-compose

# Добавить пользователя в группу docker (чтобы не писать sudo)
sudo usermod -aG docker $USER
# Применить без выхода:
newgrp docker

# Проверить установку
docker --version
docker-compose --version
```

### Проверка

```bash
# Запустить тестовый контейнер
docker run hello-world

# Посмотреть запущенные контейнеры
docker ps
```

### Если Docker не работает

```bash
# Проверить группы
groups
# Если docker нет в списке:
getent group docker
# Выйти и зайти заново по SSH
exit
ssh username@192.168.50.100 -p 2222

# Проверить снова
docker run hello-world
docker ps
```

### Создать рабочую директорию

```bash
mkdir -p ~/docker
cd ~/docker
```

---

## 2. Файлы конфигурации

### docker-compose.yml

Пример файла `docker-compose.yml` находится в папке проекта:

👉 [`../scripts/docker-compose.yml`](../scripts/docker-compose.yml)

Скопируйте его на сервер:

```bash
# На сервере:
mkdir -p ~/docker/server
```

Затем создайте или скопируйте `docker-compose.yml` в `~/docker/server/`.

### .env — переменные окружения

Пример файла `.env`:

👉 [`../scripts/.env.example`](../scripts/.env.example)

**Порядок действий:**

```bash
# 1. Скопировать пример
cp ../scripts/.env.example ~/docker/server/.env

# 2. Сгенерировать надёжные пароли и ключи
openssl rand -base64 32          # для паролей
openssl rand -hex 32             # альтернативный формат
# Выполнить несколько раз — для каждого пароля

# 3. Заполнить .env своими значениями
nano ~/docker/server/.env
```

**‼️ Важные правила безопасности:**
- Никогда не используйте пароли по умолчанию
- Добавьте `.env` в `.gitignore`: `echo ".env" >> .gitignore`
- Храните `.env` в безопасном месте — там все секреты и ключи

---

### 🔐 О безопасности паролей

#### Что такое «соль» (salt)?

Соль — это случайная строка, которая добавляется к паролю перед хешированием.
Без соли одинаковые пароли дают одинаковый хеш. С солью — каждый раз уникальный.

```text
Пример:
Пароль:           "qwerty123"
SHA256 без соли:  a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3
                  (всегда одинаковый)

С солью "a1b2c3":
Хеш:              f8c3e6a0... (уникальный)
С солью "x9y8z7":
Хеш:              2b4d7f1e... (совсем другой)
```

**Современные алгоритмы** (bcrypt, Argon2) автоматически генерируют соль при каждом хешировании — вам не нужно делать это вручную.

#### Чем хешировать пароли — bcrypt

**Bcrypt** — самый распространённый алгоритм для хеширования паролей в вебе.

```bash
# Установить на сервере (если нужна утилита для тестов)
sudo apt install -y whois    # содержит mkpasswd

# Пример генерации bcrypt-хеша из командной строки:
# (необязательно — обычно это делает само приложение)
echo "мой_пароль" | mkpasswd --method=bcrypt --stdin
# Результат: $2b$12$... (начинается с $2b$ — сигнатура bcrypt)
```

**Где используется bcrypt:**
- Flask / Django / Laravel / Node.js — по умолчанию
- Vaultwarden — для хранения мастер-пароля
- n8n — encryption key для credentials

> **Итог:**
> - Для генерации паролей и ключей: `openssl rand -base64 32`
> - Для хранения паролей пользователей: bcrypt (автоматически в Django/Flask/n8n)
> - «Соль» встраивается в алгоритм автоматически — вы просто передаёте пароль

---

## 3. Запуск и остановка сервисов

```bash
# Перейти в папку с конфигом
cd ~/docker/server

# Запустить все сервисы (скачать образы + создать контейнеры)
docker-compose up -d

# Остановить все сервисы (контейнеры удаляются)
docker-compose down

# Остановить конкретный сервис
docker-compose stop n8n

# Запустить конкретный сервис
docker-compose start n8n

# Перезапустить конкретный сервис
docker-compose restart n8n
```

---

## 4. Просмотр статуса и логов

```bash
# Все запущенные контейнеры
docker ps

# Все контейнеры (включая остановленные)
docker ps -a

# Логи конкретного сервиса (в реальном времени)
docker-compose logs -f n8n

# Логи за последние N строк
docker-compose logs --tail=50 n8n

# Статистика по всем контейнерам (CPU, RAM, сеть)
docker stats

# Информация о контейнере
docker inspect n8n
```

---

## 5. Полезные команды для работы с контейнерами

### Зайти внутрь контейнера

```bash
# Открыть bash внутри контейнера
docker exec -it n8n bash

# Выполнить одну команду внутри контейнера (без входа)
docker exec -it n8n ls -la /home/node/

# Зайти от определённого пользователя (например, root)
docker exec -it -u root n8n bash
```

### Скопировать файлы между хостом и контейнером

```bash
# Из контейнера на хост
docker cp n8n:/home/node/.n8n/database.json ~/backup/database.json

# С хоста в контейнер
docker cp ~/my-config.json n8n:/home/node/config.json
```

### Прочитать файлы внутри контейнера (без входа)

```bash
# Просто прочитать файл
docker exec n8n cat /home/node/.n8n/config

# Посмотреть логи приложения внутри контейнера
docker exec n8n tail -f /home/node/.n8n/logs/output.log
```

### Работа с образами

```bash
# Список скачанных образов
docker images

# Скачать/обновить образ конкретного сервиса
docker-compose pull n8n

# Обновить все образы
docker-compose pull

# Удалить неиспользуемые образы
docker image prune
```

### Работа с volumes (данными)

```bash
# Список томов
docker volume ls

# Информация о томе
docker volume inspect n8n_data

# Создать бэкап volume
docker run --rm -v n8n_data:/source -v ~/backup:/backup alpine tar -czf /backup/n8n_data.tar.gz -C /source .
```

### Работа с PostgreSQL через Docker

```bash

# Инициализировать и создать внутреннюю сеть 
docker network create shared_network

# Зайти в консоль PostgreSQL внутри контейнера
docker exec -it postgres psql -U user -d db

# Выполнить SQL-запрос (без входа в интерактивную консоль)
docker exec -it postgres psql -U user -d db -c "SELECT * FROM users LIMIT 5;"

# Список всех баз данных
docker exec -it postgres psql -U user -c "\l"

# Список всех таблиц в конкретной базе
docker exec -it postgres psql -U user -d n8n -c "\dt"

# Сделать дамп (бэкап) всей БД
docker exec postgres pg_dumpall -U user > ~/backup/all_databases.sql

# Восстановить из дампа
cat ~/backup/all_databases.sql | docker exec -i postgres psql -U user

# Размер всех баз данных
docker exec -it postgres psql -U user -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database ORDER BY pg_database_size(datname) DESC;"
```

---

### Очистка системы Docker

```bash
# Удалить образы без тега (dangling — <none>:<none>)
docker image prune

# Удалить все неиспользуемые образы (включая те, что не используются ни одним контейнером)
docker image prune -a

# Удалить остановленные контейнеры
docker container prune

# Удалить образ с тэгом
docker rmi nextcloud:latest

# Удалить контейнер 
docker rmi <ID container>

# Удалить всё неиспользуемое разом: контейнеры, образы, сети, кэш сборки
docker system prune -a --volumes
# ⚠️ Без --volumes volumes не трогает (данные сохраняются)
```

#### Очистка кэша и логов на сервере

```bash
# Очистить логи systemd за последнюю неделю
sudo journalctl --vacuum-time=7d

# Очистить кэш пакетов apt
sudo apt clean
sudo apt autoremove -y

# Посмотреть, сколько занимают логи Docker
# Логи контейнеров лежат в:
du -sh /var/lib/docker/containers/*/*-json.log 2>/dev/null | sort -rh | head -10

# Очистить логи конкретного контейнера
sudo truncate -s 0 /var/lib/docker/containers/$(docker ps -q --filter name=n8n)/*-json.log

# Или глобально — ограничить размер логов в docker-compose.yml:
# Добавить в сервис:
#   logging:
#     driver: json-file
#     options:
#       max-size: "10m"
#       max-file: "3"
```

---

## 6. Полезные алиасы

Добавьте в `~/.bashrc`:

```bash
alias server='cd ~/docker/server && docker-compose'
alias servers='cd ~/docker/server'

# Примеры использования:
#   server up -d          # запустить все сервисы
#   server ps             # показать статус
#   server logs n8n -f    # логи n8n
#   server down           # остановить всё
```

Применить:

```bash
source ~/.bashrc
```

---

## 7. Шпаргалка: частые сценарии

| Сценарий | Команда |
|----------|---------|
| Запустить всё в первый раз | `docker-compose up -d` |
| Перезапустить только n8n | `docker-compose restart n8n` |
| Посмотреть логи n8n | `docker-compose logs -f n8n` |
| Зайти внутрь n8n | `docker exec -it n8n bash` |
| Зайти в PostgreSQL | `docker exec -it postgres psql -U user -d db` |
| Скопировать БД из postgres | `docker exec postgres pg_dumpall -U user > backup.sql` |
| Восстановить БД | `cat backup.sql \| docker exec -i postgres psql -U user` |
| Посмотреть занятую память | `docker stats --no-stream` |
| Удалить образы без тега | `docker image prune` |
| Очистить логи journald | `sudo journalctl --vacuum-time=7d` |
| Остановить всё, сохранить данные | `docker-compose down` |
| Остановить всё и удалить volumes (‼️ данные) | `docker-compose down -v` |
| Обновить все контейнеры | `docker-compose pull && docker-compose up -d` |
