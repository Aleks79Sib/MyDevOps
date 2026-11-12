# Вот настройки для Ubuntu Server на ноутбуке:
## 1. Отключение спящего режима и работа с закрытой крышкой
- Настройка управления питанием (systemd/logind):
```bash
sudo nano /etc/systemd/logind.conf
```
```ini
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
```
- Настройка автоматического логина:
```bash
# Создаем директорию (если её нет)
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/

# Создаем файл конфигурации
sudo nano /etc/systemd/system/getty@tty1.service.d/override.conf
```ini
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ваш_username --noclear %I $TERM
```
## 2. Автозапуск SSH при загрузке
- Убедитесь, что SSH сервер установлен и включен:
```bash
sudo apt update
sudo apt install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```
- Настройка параметров SSH (опционально):
```bash
sudo nano /etc/ssh/sshd_config
```ini
#Включите параметр 
PermitRootLogin no
```
## 3. Дополнительные настройки для отключения сна
- Отключение всех режимов сна:
```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```
- Отключение автоматического сна в системе:
```bash
sudo nano /etc/systemd/sleep.conf
```ini
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowHybridSleep=no
AllowSuspendThenHibernate=no
```

## 4. Настройка BIOS/UEFI (важно!)
- Войдите в BIOS/UEFI при загрузке (обычно F2, F10, F12, Del)

- Найдите раздел Power Management и отключите:

- Suspend/Sleep mode

- Lid close action

- Adaptive/Intel SpeedStep

- C-States (или установите на C0/C1)

Включите:

- Wake on LAN/RTC (если нужно)

- Always On power state

## 5. Применить все изменения:

```bash
# Перезапустить службу logind
sudo systemctl restart systemd-logind

# Перезагрузить систему
sudo reboot

# Проверить статус после перезагрузки
systemctl status ssh
sudo systemctl status systemd-logind
```
## 6. Проверить работу:
```bash
# Проверить логи
sudo journalctl -u systemd-logind
sudo journalctl -u ssh

# Проверить доступность SSH
ssh USERNAME@localhost
```
## Важные примечания:*
**⚠️ Внимание: Ноутбук с закрытой крышкой может перегреваться. Убедитесь в хорошей вентиляции.**

- 🔄 После изменений обязательно перезагрузите систему:

```bash
sudo shutdown -r now
```
- 📊 Мониторинг температуры (рекомендуется):

```bash
sudo apt install lm-sensors
sudo sensors-detect
sensors
```
**Эти настройки позволят:**

- Работать с закрытой крышкой

- Автоматически входить в систему при загрузке

- Автозапускать SSH сервер

- Игнорировать события закрытия крышки

- Отключать все режимы сна