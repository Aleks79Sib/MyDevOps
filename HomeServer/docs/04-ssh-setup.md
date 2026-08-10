#### Настроим безопасный вход по SSH keys

- **🔑 Шаг 1: Сгенерировать SSH ключи на основном компьютере**
  - На Mac: 
```bash
# 1. Сгенерировать ключ Ed25519 (самый безопасный)
ssh-keygen -t ed25519 -C "username@name-server"

# 2. Файлы сохранятся в:
#   ~/.ssh/id_ed25519      ← приватный ключ (НЕ ДЕЛИТЬСЯ!)
#   ~/.ssh/id_ed25519.pub  ← публичный ключ

# 3. Проверить что создались
ls -la ~/.ssh/id_ed25519*
```

- **📤 Шаг 2: Скопировать публичный ключ на сервер**
  
  - Если сервер уже доступен по SSH (порт 22):
```bash
  # Автоматически скопировать ключ
ssh-copy-id username@192.168.50.100

# Или вручную:
cat ~/.ssh/id_ed25519.pub | ssh username@192.168.50.100 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```
- **🔧 Шаг 3: Настроить SSH на сервере**
  
  - Подключиться к серверу:
```bash
  ssh username@192.168.50.100
  # Пароль: тот что задал при установке
```
  - Настроить SSH демон:
```bash
# 1. Открыть конфиг SSH

sudo nano /etc/ssh/sshd_config

# 2. Внести изменения:

# Изменить порт (выбери любой от 1024 до 65535)
Port 2222

# Отключить вход по паролю (только ключи!)
PasswordAuthentication no

# Разрешить только определённых пользователей
AllowUsers username

# Отключить root вход
PermitRootLogin no

# Ограничить попытки входа
MaxAuthTries 3
LoginGraceTime 2m
ClientAliveInterval 300
X11Forwarding no

# Разрешить только ключи
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

```
**!!!**  **Важно** **Может не вступить настройки  ssh:**
```bash
# 1. Перезапустить SSH (правильно!)
sudo systemctl enable ssh
sudo systemctl restart ssh

# 2. Проверить статус
sudo systemctl status ssh

# 3. Проверить что слушает порт 2222
sudo ss -tlnp | grep ssh

#⚠️ ‼️ ВАЖНО ПЕРЕД ПЕРЕПОДКЛЮЧЕНИЕМ:
# Разреши порт 2222 в фаерволе:

sudo ufw allow 2222/tcp

#Не закрывай текущую сессию SSH на порту 22!
# ‼️ Оставь её открытой, пока не проверишь что порт 2222 работает.

#Покажи вывод после исправления:
sudo ss -tlnp | grep ssh
sudo grep -n "Port" /etc/ssh/sshd_config

# если port 22 , то возможно подключен socket activation
# Отключить socket activation
sudo systemctl disable ssh.socket --now
sudo systemctl restart ssh
sudo ss -tlnp | grep ssh
sudo grep -n "Port" /etc/ssh/sshd_config

#  если port 2222
# а удаленном другом компьтере ввыполни:
ssh -p 2222 username@192.168.50.100
# Возможно выдастошибку если был другой ключ
ssh-keygen -R [192.168.1.100]:2222

# Если подключение прошло без ошибок, то порт 2222 работает.
# Закрываем port 22:

```
- **🔑 Шаг 4: Подключиться к серверу и натсройка autossh**

```bash
# 1. Установить autossh
sudo apt install autossh -y

# 2. Создать файл для autossh
sudo nano /etc/autossh/config

# 3. Внести измнения:
ServerAliveInterval 30
ServerAliveCountMax 3




