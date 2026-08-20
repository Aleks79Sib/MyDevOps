# Расскажу о своем опыте в DevOps

Мой опыт Devops начался с "боли" развернуть собственного телеграмма бота, написанного на языке Python

Я прошел разные курсы по направлению Devops

Чему научился и что протестировал:

- [Проект Домашний сервер](./HomeServer)

- [Проекты DevOps](./Projects_DevOps/)



где развернул собственный домашний сервер и на нем тестировал различные программы open-source решения 

разворачивал некоторые программы на VPS для друзей, и иногда для себя - когда нужен "белый ip"

И так по порядку!

## Проекты по направлению Devops

### 1. [Basic Linux](./Projects_DevOps/DO1_Basic_Linux/BASIC_LINUX_RUS.MD)

### 2. [Linux Networking](./Projects_DevOps/DO2_LinuxNetwork/LINUX_NETWORKING.md)

### 3. [Bash Scripts](./Projects_DevOps/DO3_Monitoring/Bash_scripts_Linux/BASH_SCRIPTS.MD)


## Мой первый собственный HomeServer

Для собственных нужд взял старый ноутбук [такими параметрами](./HomeServer/docs/000-first-goal-and-specs.md) для тестирования возможностей OS Ubuntu Linux и получения опыта.

Определился с операционной системой и минимальным количеством программ для установки и администрирования

сейчас у меня развернуты сервисы:

- n8n ( для автоматизации процессов)
- vaultwarden (хранилище секретов)
- minikube (Kubernetes -для тестирования )
- nextcloud (облако и в качестве мессенджера)
- postgresSQL( + adminer)
- netbird (proxy )
- redis
- ollama
- agent PI
- homeassistent(умный дом)
- jellyfin (свой медиацентр)

Остальные по мере необходимости или тестирвоания

### 1. От настройки загрузочных флэшек, подготвоки компьютера , установка OS

#### 1.1. Создание загрузочной флэшки и подготовка ноутбука

Определился с [загрузочной usb](./HomeServer/docs/01-create_usb_flash_install-ubuntu.md) и первой OS Ubuntu Linux 2004 LTS - которую успешно установил на свое "старое железо"


#### 1.2. [Первое подключение и настройках параметров системы](./HomeServer/docs/03-first-connect_linux.md)

### 2.  Безопасное соединение и настройки SSH соединений

Настроим подключение по SSH - создадим ключ

#### 2.1.  [Настройки SSH соединений](./HomeServer/docs/04-ssh-setup.md)

#### 2.2. Безопасность Firewall

настроим Firewall Fail2ban 

[Firewall, Fail2ban ](./HomeServer/docs/09-security.md)

Дополнительная безопасность можно настроить g‼️port knocking‼️


### 3. Docker services (docker compose)

#### [Докер сервисы](./HomeServer/docs/05-docker-services.md)

### 4. Доступы к сервисам( Tуннели )

#### 4.1. [Cloudflare туннель](./HomeServer/docs/06-cloudflare-tunnel.md)
#### 4.2. [Реверс туннели](./HomeServer/docs/14-reverse-tunnel.md)
#### 4.3. [Прокси](./HomeServer/docs/11-openai-proxy.md)
#### 4.4. [NetBird](./HomeServer/docs/21_install_netbird.md)


### 5. Создание резервных копий и восстановление из backups

- [BACKUPS](./HomeServer/docs/15-backup.md)

- [Восстановление PostgresSQL](./HomeServer/docs/19_recovery_postgresql_from_backup.md)

- Сихронизация с S3 хранилищем [S3 Beget](./HomeServer/docs/26_BACKUPS_SERVER_to_S3_BEGET.md)


### 6. Полезные приложения 

- Управление системой [1Panel](./HomeServer/docs/20_install_1panel.md)

- [Samba](./HomeServer/docs/07-samba.md)

- [Опыт с Matrix и Coturn](./HomeServer/docs/08-matrix-coturn.md)

- Секреты [VaultWarden](./HomeServer/docs/12-vaultwarden.md)

- [Монтирование дисков](./HomeServer/docs/16-disk-mount-raid_array.md)
- [qBittorrent](./HomeServer/docs/23_install_qbittorrent.md)
- [Jellifin](./HomeServer/docs/24_install_Jellyfin.md)

### 7. Развертывание ИИ агентов и различные модели 

*моя любимая тема с ИИ*

- [Agent PI](./HomeServer/docs/18_install_agent_pi_with_docker.md)
- [OLLAMA](./HomeServer/docs/22_install_llm_ollama.md)

### 8. [Monitoring](./HomeServer/docs/13-monitoring.md)

### 9. Проблемы и решения

С чем пришлось столкнуться и как проверить и исправить

- [Проблемы и решения](./HomeServer/docs/10-troubleshooting.md)
- [Проверка на майнеров](./HomeServer/docs/25_check_mainers.md)

### 10. [Очень полезные команды](./HomeServer/docs/17-useful-commands.md)





