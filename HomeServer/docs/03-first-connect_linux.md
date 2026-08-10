# 🔌 Первое подключение и базовая настройка сервера

---

## 1. Подключение к серверу

### С основного компьютера (Mac/Windows):

```bash
# Узнать IP сервера через роутер или подключить монитор и выполнить:
ip addr show

# Подключиться по SSH (с основного ноутбука/компьютера)
ssh admin@192.168.xxx.xxx
# Пароль: заданный при установке Ubuntu
```

---

## 2. Базовые проверки после входа

После первого входа по SSH выполните проверки:

```bash
# ----- ПРОВЕРКА ПОЛЬЗОВАТЕЛЯ -----
whoami            # текущий пользователь
id                # UID, GID, группы

# ----- ПРОВЕРКА СЕТИ -----
ip a              # сетевые интерфейсы и IP-адреса
ip route          # таблица маршрутизации (шлюз по умолчанию)

# ----- ПРОВЕРКА ВНЕШНЕГО IP -----
curl -s ifconfig.me       # внешний (белый) IP
curl -s icanhazip.com     # альтернативный способ

# ----- ПРОВЕРКА ОПЕРАЦИОННОЙ СИСТЕМЫ -----
hostnamectl               # имя хоста, версия ОС, ядро
lsb_release -a            # дистрибутив и версия (Ubuntu 24.04.4)
cat /etc/os-release       # детальная информация об ОС
uname -a                  # версия ядра Linux
```

---

## 3. Настройка hostname (имя сервера)

Если нужно сменить имя сервера:

```bash
# Сменить hostname
sudo hostnamectl set-hostname home-server

# Проверить
hostnamectl

# Прописать в /etc/hosts (чтобы локально резолвилось)
sudo sed -i "s/127.0.1.1.*/127.0.1.1 home-server/" /etc/hosts

# Проверить
cat /etc/hosts
```

---

## 4. Настройка статического IP-адреса

По умолчанию сервер получает IP по DHCP. Чтобы адрес не менялся после перезагрузки, настройте статический IP через **Netplan**:

```bash
# Найти имя сетевого интерфейса
ip a
# Обычно: enp0s3, eth0, ensXX и т.д.

# Посмотреть текущий конфиг Netplan
ls /etc/netplan/
cat /etc/netplan/00-installer-config.yaml
```

```bash
# Отредактировать конфиг
sudo nano /etc/netplan/00-installer-config.yaml
```

```yaml
# Пример конфига для статического IP:
network:
  ethernets:
    enp0s3:                         # заменить на свой интерфейс
      addresses:
        - 192.168.1.100/24         # нужный статический IP
      routes:
        - to: default
          via: 192.168.1.1          # шлюз (роутер)
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
  version: 2
```

```bash
# Применить настройки
sudo netplan apply

# Проверить новый IP
ip a
```

> ⚠️ **Важно:** Если вы подключены по SSH, после `netplan apply` IP может измениться.
> Подключитесь заново по новому адресу: `ssh admin@192.168.1.5`

---

## 5. Добавление пользователя в группы

```bash
# Добавить пользователя в группу sudo (если ещё не добавлен)
sudo usermod -aG sudo $USER

# Добавить в группу adm (для доступа к логам)
sudo usermod -aG adm $USER

# Проверить группы
groups $USER

# Применить без выхода
exec su - $USER
```

> **Примечание:** Группа `docker` будет добавлена позже, после установки Docker.

---

## 6. Отключение спящего режима и автологин

Для работы сервера с закрытой крышкой ноутбука необходимо отключить спящий режим.

Подробная инструкция: [`instructionHybernation.md`](instructionHybernation.md)

---

## 7. Первые команды на сервере

### 7.1. Обновить систему

```bash
# Подключить Ubuntu Pro (бесплатный токен для personal use)
sudo pro attach ВАШ_ТОКЕН

# Обновить пакеты
sudo apt update && sudo apt upgrade -y
```

### 7.2. Установить базовые утилиты

```bash
# ZRAM — сжатие ОЗУ (для экономии памяти)
sudo apt install zram-tools
# Отредактировать: sudo nano /etc/default/zramswap, добавить PERCENT=50

# Базовые утилиты
sudo apt install -y htop btop ncdu neofetch git curl wget unzip \
                    ufw fail2ban net-tools nmap autossh
```

### 7.3. Настроить часовой пояс

```bash
sudo timedatectl set-timezone Europe/Moscow
timedatectl    # проверить
```

### 7.4. Проверка дисков

```bash
# Список дисков и разделов
lsblk
# или
sudo fdisk -l

# Использование дискового пространства
df -h

# Информация о конкретных дисках (если нужно)
sudo blkid                    # UUID разделов
sudo smartctl -a /dev/sda     # SMART-статус (если установлен smartmontools)
```

### 7.5. Создать структуру папок для сервисов

```bash
# Создать папки
sudo mkdir -p /data/{homeassistant,media,backups,documents,supabase,n8n,jellyfin,samba}

# Проверить созданную структуру
ls -la /data/

# Проверить размеры папок (пока пустые, но для контроля в будущем)
sudo du -sh /data/*

# Альтернатива — визуальная проверка
ncdu /data/
```

### 7.6. Настроить права на папки

```bash
# Для n8n (UID 1000 — стандартный ID первого пользователя)
sudo chown -R 1000:1000 /data/n8n

# Проверить права
ls -lan /data/n8n/
# Должно быть: drwxr-xr-x  2 1000 1000 ...
```

### 7.7. Финальная проверка системы

```bash
# Сводная информация
neofetch 
# или
sudo apt install fastfetch

# Использование памяти
free -h

# Загрузка процессора
htop
# или
btop

# Состояние дисков
df -h
lsblk

```
---

### 7.8. Добавить файл подкачки

Создай swapfile на 8 ГБ (если его ещё нет)

```bash
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

Добавь его в /etc/fstab для автозагрузки

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

Настрой приоритет, чтобы сначала использовался zram

```bash
sudo swapoff /swapfile
sudo swapon -p 0 /swapfile
```

Проверь использование swapfile

```bash
swapon --show
```
```
NAME       TYPE      SIZE USED PRIO
/swap.img  file        8G   0B   -1
/dev/zram0 partition  15G   0B  100
/swapfile  file        8G   0B    0
```

## 🎯 Золотые правила

| Правило | Описание |
|---------|----------|
| **UID/GID** | Всегда используйте цифровые UID/GID (1000), а не имена пользователей, для папок, монтируемых в Docker |
| **Docker volumes** | Вместо bind-монтирования лучше использовать Docker volumes — Docker сам управляет правами |
| **Перезагрузка** | После изменений сети (Netplan) не закрывайте текущую SSH-сессию, пока не проверите новое подключение |
