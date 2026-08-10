# Инструкция для восстановления PostgreSQL из бэкапов

## 1. Очистка и подготовка папки данных

```bash
sudo rm -rf /var/lib/postgresql/data/*
sudo mkdir -p /var/lib/postgresql/data
sudo chown -R 999:999 /var/lib/postgresql/data
```

## 2. Запуск контейнера Postgres
*(через docker-compose или вручную)*

```bash
docker compose up -d
docker compose ps
```

## 3. Создание необходимых баз данных (если дамп не кластерный)

**(Если используешь ‼️init.sql, можно пропустить этот шаг).**

```bash
docker exec -it postgres psql -U lorydari -c "CREATE DATABASE nextcloud;"
docker exec -it postgres psql -U lorydari -c "CREATE DATABASE n8n_v2_db;"
docker exec -it postgres psql -U lorydari -c "CREATE DATABASE \"PSQL_Supabase\";"
```

## 4. Восстановление дампа (заливка SQL-файла)

```bash
docker exec -i postgres psql -U lorydari -d postgres < /путь/к/дампам/postgres_all.sql
```

## 5. Приведение пароля в соответствие с .env

```bash
docker exec -it postgres psql -U lorydari -c "ALTER USER lorydari WITH PASSWORD 'новый_пароль_из_env';"
```

## 6. Проверка состояния баз

```bash
docker exec -it postgres psql -U lorydari -c "\l"
```

## 7. Полезные команды Работа с PostgreSQL через Docker

```bash
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