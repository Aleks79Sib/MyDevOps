# Инструкция по установке multipass на примере MacBook Pro M1 (Apple Silicon)

## Подготовительный этап

### 1. Установка Multipass

Вы можете установить multipass на разных ОС (Linux, macOS, Windows ) вашего компьютера 

На MacBook Pro M1 (Apple Silicon) используется [**Multipass**](https://canonical.com/multipass/docs/latest/how-to-guides/install-multipass/) — официальная утилита от Canonical (Ubuntu) для быстрого создания Ubuntu VM на ARM-архитектуре.

**Установка через Homebrew:**
```bash
brew install multipass
```

**Проверка установки:**
```bash
multipass version
```
Ожидаемый вывод:
```
multipass   1.16.3+mac
multipassd  1.16.3+mac
```

**Проверка драйвера (на M1 должен быть qemu):**
```bash
multipass get local.driver
```
Ожидаемый вывод: `qemu`

Multipass по умолчанию использует QEMU в качестве поставщика виртуализации. 
Если вы хотите использовать AppleVZ, вы можете сделать это, используя следующую команду:
```bash
multipass set local.driver=applevz
```


---

### 2. Создание виртуальных машин

Для проекта вы можете создать несколько ВМ:
Назовем сокращено наши ммашины workstation
- **ci-vm** — 
- **deploy-vm** — 

#### Создание ci-vm:
```bash
multipass launch 24.04 --name ci-vm --cpus 2 --memory 4G --disk 20G
```
при создании сразу указываем:
- название: `--name ci-vm`
- размер cpu: `--cpus 2`
- размер выделенной памяти ОЗУ: `--memory 4G`
- размер диска: `--disk 20G`

#### Создание deploy-vm :
```bash
multipass launch 24.04 --name deploy-vm --cpus 1 --memory 2G --disk 10G
```

**Параметры:**
- `--cpus` — количество ядер CPU
- `--memory` — объём оперативной памяти
- `--disk` — объём дискового пространства

---

### 3. Базовые команды для работы с ВМ

#### 3.1 Просмотр списка VM и их статуса:
```bash
multipass list
```

Ожидаемый вывод:
```
Name                    State             IPv4             Image
ci-vm                   Running           192.168.252.2    Ubuntu 24.04 LTS
deploy-vm               Running           192.168.252.3    Ubuntu 24.04 LTS
```

#### 3.2 Подключение к VM:
```bash
# Интерактивный вход
multipass shell ci-vm
multipass shell deploy-vm

# Выполнение команды без входа
multipass exec ci-vm -- <команда>
multipass exec deploy-vm -- <команда>
```

#### 3.3 Управление VM:

| Действие | Команда |
|----------|---------|
| Остановить ВМ | `multipass stop ci-vm` |
| Запустить ВМ | `multipass start ci-vm` |
| Перезапустить ВМ | `multipass restart ci-vm` |
| Удалить ВМ | `multipass delete ci-vm && multipass purge` |
| Информация о ВМ | `multipass info ci-vm` |

---

### 4. Установка дополнительных пакетов на ci-vm

#### 4.1. build-essential (make, gcc, g++)

```bash
multipass exec ci-vm -- sudo apt-get install -y build-essential
```

#### 4.2. clang-format (проверка кодстайла)

```bash
multipass exec ci-vm -- sudo apt-get install -y clang-format
```

---

### 5. Настройка статических IP через netplan

По умолчанию Multipass выдаёт IP по DHCP. Статический IP нужен, чтобы адреса ВМ не менялись после перезагрузки — иначе скрипт деплоя перестанет работать.

#### 5.1. Узнать текущие настройки сети

Зайти в ВМ и выполнить:
```bash
# Посмотреть шлюз
ip route | grep default

# Посмотреть DNS
resolvectl status | grep "DNS Servers"

# Посмотреть имя интерфейса
ip a
```

#### 5.2. Настроить статический IP на ci-vm

```bash
multipass exec ci-vm -- sudo bash -c 'cat > /etc/netplan/50-cloud-init.yaml << EOF
network:
  version: 2
  ethernets:
    enp0s1:
      dhcp4: false
      addresses:
        - 192.168.252.2/24
      routes:
        - to: default
          via: 192.168.252.1
      nameservers:
        addresses:
          - 192.168.252.1
EOF
'
multipass exec ci-vm -- sudo netplan apply
```

#### 5.3. Настроить статический IP на deploy-vm

```bash
multipass exec deploy-vm -- sudo bash -c 'cat > /etc/netplan/50-cloud-init.yaml << EOF
network:
  version: 2
  ethernets:
    enp0s1:
      dhcp4: false
      addresses:
        - 192.168.252.3/24
      routes:
        - to: default
          via: 192.168.252.1
      nameservers:
        addresses:
          - 192.168.252.1
EOF
'
multipass exec deploy-vm -- sudo netplan apply
```

#### 5.4. Проверка

```bash
multipass exec ci-vm -- ip a show enp0s1 | grep inet
multipass exec deploy-vm -- ip a show enp0s1 | grep inet
```

Ожидаемый вывод для ci-vm:
```
inet 192.168.252.2/24 brd ...
```
Ожидаемый вывод для deploy-vm:
```
inet 192.168.252.3/24 brd ...
```

---

### 6. Настройка SSH между ВМ

SSH нужен для этапа деплоя (Part 5) — скрипт будет копировать файлы с ci-vm на deploy-vm.

#### 6.1. Сгенерировать SSH-ключ на ci-vm

```bash
multipass exec ci-vm -- bash -c 'ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519'
```

#### 6.2. Скопировать ключ на deploy-vm

```bash
multipass exec ci-vm -- bash -c 'cat ~/.ssh/id_ed25519.pub' | multipass exec deploy-vm -- bash -c 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

#### 6.3. Проверка SSH

```bash
multipass exec ci-vm -- ssh -o StrictHostKeyChecking=no ubuntu@192.168.252.3 "hostname"
```

Ожидаемый вывод: `deploy-vm`

---

### Part 7. Финальный этап

#### 7.1. Создание дампов образов ВМ

> ⚠️ **ВАЖНО: Ни в коем случае не сохраняй дампы в гит!**
> Дампы сохраняются в папку `src/dump/`, которая исключена из git через `.gitignore`.

Дампы — это архивы образов ВМ, чтобы можно было восстановить их в рабочем состоянии.

**Размер:**
- ci-vm: ~2 GB
- deploy-vm: ~1.8 GB
- После архивации (gzip): ~1-2 GB каждый

#### 7.2 Создать архив ci-vm:
```bash
sudo tar -czf src/dump/ci-vm-dump.tar.gz \
  -C /var/root/Library/Application\ Support/multipassd/qemu/vault/instances/ ci-vm
```

#### 7.2 Создать архив deploy-vm:
```bash
sudo tar -czf src/dump/deploy-vm-dump.tar.gz \
  -C /var/root/Library/Application\ Support/multipassd/qemu/vault/instances/ deploy-vm
```

#### 7.3 Сменить владельца:
```bash
sudo chown $(whoami) src/dump/*.tar.gz
```

#### 7.4 Проверить:
```bash
ls -lh src/dump/
```

#### 7.5. Восстановление ВМ из архива

Если ВМ была удалена или повредилась:

```bash
# Удалить текущую ВМ (если есть)
multipass delete ci-vm && multipass purge

# Распаковать архив в папку Multipass
sudo tar -xzf src/dump/ci-vm-dump.tar.gz \
  -C /var/root/Library/Application\ Support/multipassd/qemu/vault/instances/

# Запустить ВМ
multipass start ci-vm

# Проверить
multipass list
multipass exec ci-vm -- hostname
```

**Примечание:** После восстановления IP адреса могут измениться — нужно перенастроить статику через netplan (см. [раздел 5](#5-настройка-статических-ip-через-netplan)).



### Приложение. Полезные alias для терминала

```bash
alias cish='multipass shell ci-vm'
alias desh='multipass shell deploy-vm'
alias cip='multipass info ci-vm'
alias vlist='multipass list'
```

Добавить в `~/.zshrc`:
```bash
echo alias cish=\'multipass shell ci-vm\' >> ~/.zshrc
echo alias desh=\'multipass shell deploy-vm\' >> ~/.zshrc
echo alias cip=\'multipass info ci-vm\' >> ~/.zshrc
echo alias vlist=\'multipass list\' >> ~/.zshrc
source ~/.zshrc
```
