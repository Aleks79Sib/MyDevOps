# 💾 Бэкап — резервное копирование

---

## 1. Установка rclone

```bash
sudo apt update
sudo apt install rclone -y

# Проверить
rclone --version
# Ответ:
# rclone v1.60.1-DEV
# - os/version: ubuntu 24.04 (64 bit)
# - os/kernel: 6.8.0-117-generic (x86_64)
# - os/type: linux
# - os/arch: amd64
# - go/version: go1.22.2
# - go/linking: dynamic
# - go/tags: none
```

---

## 2. Настройка хранилища (Beget S3)

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

```

| Параметр | Значение |
|----------|----------|
| Имя | `beget` |
| Тип | `s3` (другой S3-совместимый) |
| Provider | `Other` |
| access_key_id | ваш ключ |
| secret_access_key | ваш секрет |
| region | `ru1` |
| endpoint | `https://...s3.ru1.storage.beget.cloud` |
| acl | `private` |

```bash
# Проверить подключение
rclone ls beget:
```

---

## 3. Скрипт автоматического бэкапа

- Создаем скрипты для бэкапов

```bash
sudo nano ~/scripts/daily_backup.sh
sudo chmod +x ~/scripts/daily_backup.sh

sudo nano ~/scripts/full_backup.sh
sudo chmod +x ~/scripts/full_backup.sh

# Добавим права доступа
sudo chmod -R 755 /var/lib/nextcloud
sudo chmod -R 755 /storage/nextcloud/data
```
* ⏰ Расписание (crontab)
```bash
sudo crontab -e

no crontab for lorydari - using an empty one

Select an editor.  To change later, run 'select-editor'.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.basic
  3. /usr/bin/vim.tiny
  4. /bin/ed

Choose 1-4 [1]: 1

#  Добавляем строки 
0 3 * * 1,3,5 /home/lorydari/scripts/daily_backup.sh >> /storage/backups/NewServer/logs/daily.log 2>&1
0 3 * * 3 /home/lorydari/scripts/full_backup.sh >> /storage/backups/NewServer/logs/full.log 2>&1

sudo crontab -l

```
- Примеры скриптов

👉 [Daily_backup](/Version_2/HS/scripts/daily_backup.sh)

👉 [Full_backup](/Version_2/HS/scripts/full_backup.sh)

Скрипт делает:
- Дамп PostgreSQL всех баз
- Архив данных n8n, Nextcloud, Vaultwarden, Qdrant
- Отправку архива в Beget S3
- Автоматическую очистку старых копий (хранить 3 последних)

*🛡️ Секретный лайфхак*, чтобы в будущем не париться с путями в crontab

Если ты часто будешь менять расположение скриптов, 
сделай так: положи файлы в /usr/local/bin, 
но не через копирование, а через символическую ссылку:
```bash
sudo ln -s /home/lorydari/scripts/daily_backup.sh /usr/local/bin/daily_backup.sh
sudo ln -s /home/lorydari/scripts/full_backup.sh /usr/local/bin/full_backup.sh
```
- Финальный тест для cron:
Выполни в терминале:

```bash


/home/lorydari/scripts/daily_backup.sh >> /storage/backups/NewServer/logs/daily.log 2>&1

# Затем загляни в лог:

cat /storage/backups/NewServer/logs/daily.log
```
---


## 4. Ручные бэкапы

```bash
# Дамп всех БД
docker exec postgres pg_dumpall -U user > ~/backup/all_databases.sql

# Архив данных
tar -czf ~/backup/backup-$(date +%Y%m%d).tar.gz /data

# Восстановление
tar -xzf ~/backup/backup-20250101.tar.gz -C /

# Копирование на другой сервер
rsync -avhP ~/backup/backup-*.tar.gz user@backup-server:/backups/
```

---

## 5. Шпаргалка

| Сценарий | Команда |
|----------|---------|
| Установить rclone | `sudo apt install rclone -y` |
| Настроить rclone | `rclone config` |
| Проверить S3 | `rclone ls beget:n8n-backups/` |
| Запустить бэкап | `sudo /usr/local/bin/backup_all.sh` |
| Дамп БД | `docker exec postgres pg_dumpall -U user > backup.sql` |
| Восстановить БД | `cat backup.sql \| docker exec -i postgres psql -U user` |
| Архив данных | `tar -czf backup.tar.gz /data` |
| Расписание crontab | `crontab -e` |
