# Расскажу о своем опыте в DevOps

Мой опыт Devops начался с "боли" развернуть собственного телеграмма бота, написанного на языке Python

Я поступил в Школу 21 по направлению Devops

Чему научился и что протестировал:

- [Проекты Школы 21](./Projects_School21)

- [Проект Домашний сервер](./HomeServer)
где развернул собственный домашний сервер и на нем тестировал различные selfhost решения 

разворачивал некоторые программы на VPS для друзей, и иногда для себя - когда нужен "белый ip"

И так по порядку!

## Проекты по направлению Devops

### [Basic Linux](./Projects_School21/DO1_Basic_Linux/BASIC_LINUX_RUS.MD)

### [Linux Networking](./Projects_School21/DO2_LinuxNetwork/LINUX_NETWORKING.md)


## Мой первый собственный HomeServer

Для собственных нужд я определился с целями с чтобы хотелось для использования и взял старый ноутбук вот с [такими параметрами](./HomeServer/docs/000-first-goal-and-specs.md)

### 1 От настройки загрузочных флэшек, подготвоки компьютера , установка OS

#### 1.1 Создание загрузочной флэшки и подготовка ноутбука

Определился с [загрузочной usb](./HomeServer/docs/01-create_usb_flash_install-ubuntu.md) и первой OS Ubuntu Linux 2004 LTS - которую успешно установил на свое "старое железо"


#### 1.2 [Первое подключение и настройках параметров](./HomeServer/docs/03-first-connect_linux.md)

### 2  Безопасное соединение и настройки SSH соединений

Настроим подключение по SSH - создадим ключ

#### 2.1  [настройки SSH соединений](./HomeServer/docs/04-ssh-setup.md)

#### 2.2 Безопасность Firewall

настроим Firewall Fail2ban 

[Firewall, Fail2ban ](./HomeServer/docs/09-security.md)

Дополнительная безопасность можно настроить g‼️port knocking‼️


### 3 Docker services

#### [Докер сервисы](./HomeServer/docs/05-docker-services.md)

### 4 Доступы к сервисам( Tуннели )

#### 4.1 [Cloudflare туннель](./HomeServer/docs/06-cloudflare-tunnel.md)
#### 4.2 [Реверс туннели](./HomeServer/docs/14-reverse-tunnel.md)
#### 4.3 [Прокси](./HomeServer/docs/11-openai-proxy.md)
#### 4.4 [NetBird](./HomeServer/docs/21_install_netbird.md)

### [BACKUPS](./HomeServer/docs/15-backup.md)
### [Восстановление PostgresSQL](./HomeServer/docs/19_recovery_postgresql_from_backup.md)



### [Samba](./HomeServer/docs/07-samba.md)

### [Опыт с Matrix и Coturn](./HomeServer/docs/08-matrix-coturn.md)





### [VaultWarden](./HomeServer/docs/12-vaultwarden.md)

### [Monitoring](./HomeServer/docs/13-monitoring.md)

### [Монтирование дисков](./HomeServer/docs/16-disk-mount-raid_array.md)

### [Agent PI](./HomeServer/docs/18_install_agent_pi_with_docker.md)

### [1Panel](./HomeServer/docs/20_install_1panel.md)


### [OLLAMA](./HomeServer/docs/22_install_llm_ollama.md)
### [qBittorrent](./HomeServer/docs/23_install_qbittorrent.md)
### [Jellifin](./HomeServer/docs/24_install_Jellyfin.md)
### [Проверка на майнеров](./HomeServer/docs/25_check_mainers.md)

### [Проблемы и решения](./HomeServer/docs/10-troubleshooting.md)

### [Очень полезные команды](./HomeServer/docs/17-useful-commands.md)




