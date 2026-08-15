# 📦 Готовая настройка для Beget на S3 хранилища 
**НИКОГДА НЕ ЗАБЫВАЙ ДЕЛАТЬ ‼️BACKUP‼️**

*Напишем определенную стратегиюпо созданию резервной копии*

**А то можно ПОТЕРЯТЬ ДАННЫЕ безвозвратно**

## Шаг 1: Зайти на сервер и установить rclone

Подключитесь к вашему серверу по SSH и выполните:

```bash
# Скачиваем и устанавливаем rclone
sudo apt update
sudo apt install rclone -y

# Проверяем, что установилось
rclone --version

# Ответ
rclone --version
rclone v1.60.1-DEV
- os/version: ubuntu 24.04 (64 bit)
- os/kernel: 6.8.0-117-generic (x86_64)
- os/type: linux
- os/arch: amd64
- go/version: go1.22.2
- go/linking: dynamic
- go/tags: none
```

## Шаг 2: Настройка подключения к Beget S3
Теперь запустите настройку:

```bash
rclone config

# Далее
2026/05/29 20:13:53 NOTICE: Config file "/home/lorydari/.config/rclone/rclone.conf" not found - using defaults
No remotes found, make a new one?
n) New remote
s) Set configuration password
q) Quit config
n/s/q> 
# Введите n
Enter name for new remote.
name> beget
Option Storage.
Type of storage to configure.
Choose a number from below, or type in your own value.
1 / 1Fichier
   \ (fichier)
 2 / Akamai NetStorage
   \ (netstorage)
 3 / Alias for an existing remote
   \ (alias)
 4 / Amazon Drive
   \ (amazon cloud drive)
 5 / Amazon S3 Compliant Storage Providers including AWS, Alibaba, Ceph, China Mobile, Cloudflare, ArvanCloud, Digital Ocean, Dreamhost, Huawei OBS, IBM COS, IDrive e2, IONOS Cloud, Lyve Cloud, Minio, Netease, RackCorp, Scaleway, SeaweedFS, StackPath, Storj, Tencent COS, Qiniu and Wasabi
   \ (s3)
# Вводим 5
5

# Вводим провайдера
Option provider.
Choose your S3 provider.
Choose a number from below, or type in your own value.
Press Enter to leave empty.
 1 / Amazon Web Services (AWS) S3
   \ (AWS)
 2 / Alibaba Cloud Object Storage System (OSS) formerly Aliyun
   \ (Alibaba)

 ------
23 / Qiniu Object Storage (Kodo)
   \ (Qiniu)
24 / Any other S3 compatible provider
   \ (Other)
provider> 24
Option env_auth.
Get AWS credentials from runtime (environment variables or EC2/ECS meta data if no env vars).
Only applies if access_key_id and secret_access_key is blank.
Choose a number from below, or type in your own boolean value (true or false).
Press Enter for the default (false).
 1 / Enter AWS credentials in the next step.
   \ (false)
 2 / Get AWS credentials from the environment (env vars or IAM).
   \ (true)
env_auth> 1

Option access_key_id.
AWS Access Key ID.
Leave blank for anonymous access or runtime credentials.
Enter a value. Press Enter to leave empty.
access_key_id> 9BXXXXXXXXXXX6

Option secret_access_key.
AWS Secret Access Key (password).
Leave blank for anonymous access or runtime credentials.
Enter a value. Press Enter to leave empty.
secret_access_key> ZZZZZZZZZZZZZZZZZZ

Option region.
Region to connect to.
Leave blank if you are using an S3 clone and you don't have a region.
Choose a number from below, or type in your own value.
Press Enter to leave empty.
   / Use this if unsure.
 1 | Will use v4 signatures and an empty region.
   \ ()
   / Use this only if v4 signatures don't work.
 2 | E.g. pre Jewel/v10 CEPH.
   \ (other-v2-signature)
region> ru1

Option endpoint.
Endpoint for S3 API.
Required when using an S3 clone.
Enter a value. Press Enter to leave empty.
endpoint> https://5ad68715e105-intelligent-stream.s3.ru1.storage.beget.cloud

Option location_constraint.
Location constraint - must be set to match the Region.
Leave blank if not sure. Used when creating buckets only.
Enter a value. Press Enter to leave empty.
location_constraint> 

Option acl.
Canned ACL used when creating buckets and storing or copying objects.
This ACL is used for creating objects and if bucket_acl isn't set, for creating buckets too.
For more info visit https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl
Note that this ACL is applied when server-side copying objects as S3
doesn't copy the ACL from the source but rather writes a fresh one.
Choose a number from below, or type in your own value.
Press Enter to leave empty.
   / Owner gets FULL_CONTROL.
 1 | No one else has access rights (default).
   \ (private)
   / Owner gets FULL_CONTROL.
 2 | The AllUsers group gets READ access.
   \ (public-read)
   / Owner gets FULL_CONTROL.
 3 | The AllUsers group gets READ and WRITE access.
   | Granting this on a bucket is generally not recommended.
   \ (public-read-write)
   / Owner gets FULL_CONTROL.
 4 | The AuthenticatedUsers group gets READ access.
   \ (authenticated-read)
   / Object owner gets FULL_CONTROL.
 5 | Bucket owner gets READ access.
   | If you specify this canned ACL when creating a bucket, Amazon S3 ignores it.
   \ (bucket-owner-read)
   / Both the object owner and the bucket owner get FULL_CONTROL over the object.
 6 | If you specify this canned ACL when creating a bucket, Amazon S3 ignores it.
   \ (bucket-owner-full-control)
acl> 1

Edit advanced config?
y) Yes
n) No (default)
y/n> n

Configuration complete.
Options:
- type: s3
- provider: Other
- access_key_id: 9BXXXXXXXXXXX6
- secret_access_key: ZZZZZZZZZZZZZZZZZZ
- region: ru1
- endpoint: https://5ad68715e105-intelligent-stream.s3.ru1.storage.beget.cloud
- acl: private
Keep this "beget" remote?
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d> y

Current remotes:

Name                 Type
====                 ====
beget                s3

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q> q

# Создаём тестовый файл
echo "test" > /tmp/test.txt

# Копируем напрямую в существующую папку
rclone copy /tmp/test.txt beget:n8n-backups/

# Проверка на панели в Beget
rclone ls beget:n8n-backups/
```
* Копируем в папку

🚀 Готовый скрипт бэкапа  ежедневного
```bash
sudo nano /usr/local/bin/backup_all.sh
```
```
#!/bin/bash

# ===== НАСТРОЙКИ =====
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/backup_$BACKUP_DATE"
KEEP_COUNT=3
S3_REMOTE="beget"
S3_PATH="n8n-backups"

# Папки для бэкапа (bind mounts)
POSTGRES_V2_DATA="/var/lib/postgresql/data_v2"
POSTGRES_DATA="/var/lib/postgresql/data"
N8N_DATA="/var/lib/postgresql/n8n_v2_data"
NEXTCLOUD_DATA="/var/lib/postgresql/nextcloud_data"
VAULTWARDEN_DATA="/var/lib/vaultwarden_data"
QDRANT_DATA="/var/lib/postgresql/qdrant_storage"

mkdir -p $BACKUP_DIR

echo "[$(date)] Начинаем бэкап всех сервисов..."

# === 1. ДАМПЫ БАЗ ДАННЫХ (автоматически из переменных контейнера) ===
echo ">>> Дамп PostgreSQL (основная)..."

# Получаем пользователя и БД из контейнера
PG_USER=$(docker exec postgres env | grep POSTGRES_USER | cut -d= -f2)
PG_DB=$(docker exec postgres env | grep POSTGRES_DB | cut -d= -f2)

if [ -n "$PG_USER" ] && [ -n "$PG_DB" ]; then
    docker exec postgres pg_dumpall -U "$PG_USER" > $BACKUP_DIR/postgres_all.sql 2>/dev/null
    echo "    Дамп создан (пользователь: $PG_USER)"
else
    # Пробуем без указания пользователя
    docker exec postgres pg_dumpall > $BACKUP_DIR/postgres_all.sql 2>/dev/null
    echo "    Дамп создан (без указания пользователя)"
fi

echo ">>> Дамп PostgreSQL_v2 (n8n)..."
PG_USER2=$(docker exec postgres_v2 env | grep POSTGRES_USER | cut -d= -f2)
PG_DB2=$(docker exec postgres_v2 env | grep POSTGRES_DB | cut -d= -f2)

if [ -n "$PG_USER2" ] && [ -n "$PG_DB2" ]; then
    docker exec postgres_v2 pg_dumpall -U "$PG_USER2" > $BACKUP_DIR/postgres_v2_all.sql 2>/dev/null
    echo "    Дамп создан (пользователь: $PG_USER2)"
else
    docker exec postgres_v2 pg_dumpall > $BACKUP_DIR/postgres_v2_all.sql 2>/dev/null
    echo "    Дамп создан (без указания пользователя)"
fi

# === 2. АРХИВЫ ДАННЫХ ===
echo ">>> Архив n8n..."
tar -czf $BACKUP_DIR/n8n_data.tar.gz -C $N8N_DATA . 2>/dev/null

echo ">>> Архив Nextcloud..."
tar -czf $BACKUP_DIR/nextcloud_data.tar.gz -C $NEXTCLOUD_DATA . 2>/dev/null

echo ">>> Архив Vaultwarden..."
tar -czf $BACKUP_DIR/vaultwarden_data.tar.gz -C $VAULTWARDEN_DATA . 2>/dev/null

echo ">>> Архив Qdrant..."
tar -czf $BACKUP_DIR/qdrant_data.tar.gz -C $QDRANT_DATA . 2>/dev/null

# === 3. УПАКОВКА ===
echo ">>> Создание итогового архива..."
cd $BACKUP_DIR
tar -czf /tmp/backup_all_${BACKUP_DATE}.tar.gz . 2>/dev/null

# === 4. ОТПРАВКА В BEGET S3 ===
echo ">>> Отправка в Beget S3..."
rclone copy /tmp/backup_all_${BACKUP_DATE}.tar.gz $S3_REMOTE:$S3_PATH/

# === 5. ЧИСТКА СТАРЫХ ===
echo ">>> Очистка старых бэкапов (оставляем $KEEP_COUNT)..."
rclone lsf $S3_REMOTE:$S3_PATH/ | grep "backup_all_.*\.tar\.gz" | sort | head -n -$KEEP_COUNT | while read file; do
    rclone deletefile "$S3_REMOTE:$S3_PATH/$file"
    echo "Удалён: $file"
done

# === 6. ЛОКАЛЬНАЯ ЧИСТКА ===
rm -rf $BACKUP_DIR
rm /tmp/backup_all_${BACKUP_DATE}.tar.gz

echo "[$(date)] Бэкап завершён! Файл: backup_all_${BACKUP_DATE}.tar.gz"
```
```bash
# Даем право на выполнение скрипта
sudo chmod +x /usr/local/bin/backup_all.sh
```
* ⏰ Расписание (crontab)
```bash
crontab -e

no crontab for lorydari - using an empty one

Select an editor.  To change later, run 'select-editor'.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.basic
  3. /usr/bin/vim.tiny
  4. /bin/ed

Choose 1-4 [1]: 1

# Добавьте (например, каждый понедельник, среду, пятницу в 3:00):
0 3 * * 1,3,5 /usr/local/bin/backup_all.sh

# Проверить
sudo crontab -l

#  Делаем файл исполняемым
sudo chmod +x /usr/local/bin/backup_all.sh

# Запуск  в ручную скрипта
/usr/local/bin/backup_all.sh

# Вывод
[Fri May 29 21:42:44 MSK 2026] Начинаем бэкап всех сервисов...
>>> Дамп PostgreSQL (основная)...
    Дамп создан (пользователь: lorydari)
>>> Дамп PostgreSQL_v2 (n8n)...
    Дамп создан (пользователь: lorydari)
>>> Архив n8n...
>>> Архив Nextcloud...
>>> Архив Vaultwarden...
>>> Архив Qdrant...
>>> Создание итогового архива...
>>> Отправка в Beget S3...
>>> Очистка старых бэкапов (оставляем 3)...
[Fri May 29 21:44:42 MSK 2026] Бэкап завершён! Файл: backup_all_20260529_214244.tar.gz

# Проверяем на панели Beget что файл сохранился !

```
- Проверка данных на тестовом сервере