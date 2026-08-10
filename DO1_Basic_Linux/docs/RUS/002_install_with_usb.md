## 🛠️ Установка и настройка

### 📝 Шаг 1: Подготовка загрузочной флешки
#### На Windows (основной ноутбук):
1. **Скачать:**
[Ubuntu Server 24.04.04 LTS](https://releases.ubuntu.com/24.04/ubuntu-24.04.4-live-server-amd64.iso)

2. **Скачать (Windows):** [Rufus](https://rufus.ie/ru/)

3. **Создать загрузочную флешку:**

- **Устройство:** Флешка 32 ГБ
- **Метод загрузки:** Выбрать ISO файл
- **Схема раздела:** MBR (для BIOS или UEFI-CSM)
- **Целевая система:** BIOS или UEFI-CSM
- **Файловая система:** FAT32
- **Нажать:** СТАРТ → Записать в режиме DD-образа


#### На macOS (Apple Silicon / Intel):
1. **Скачать:**
[Ubuntu Server 24.04.04 LTS](https://releases.ubuntu.com/24.04/ubuntu-24.04.4-live-server-amd64.iso)

2. **Создать загрузочную флешку через терминал (```dd```):**

- Подключить флешку (минимум 8 ГБ)
- Открыть **Терминал**
- Определить диск флешки:
  ```bash
  diskutil list
  ```
  Найти USB-диск (например, `/dev/disk2`)

- Размонтировать флешку:
  ```bash
  diskutil unmountDisk /dev/disk2
  ```

- Записать ISO на флешку:
  ```bash
  sudo dd if=~/Downloads/ubuntu-24.04.4-live-server-amd64.iso of=/dev/rdisk2 bs=1m status=progress
  ```
  ⏳ Ждать 5–10 минут. После завершения появится надпись `records in / records out`.

- Извлечь флешку:
  ```bash
  diskutil eject /dev/disk2
  ```

**Альтернатива:** [balenaEtcher](https://etcher.balena.io/) — графическая утилита, работает на Intel и Apple Silicon.

---

#### Проверка:
- Флешка должна определяться в BIOS как "USB HDD"
- При загрузке появляется меню Ubuntu

---

### ⚙️ Шаг 2: Настройка BIOS
#### Вход в BIOS:
- Перезагрузить ноутбук
- Нажать **F2** при запуске

#### Настройки:

- **Boot** → Boot priority order:

- **USB HDD**
- **ADATA SU650**

- Остальные отключить

- **Security** → Password on Boot: Disabled

- **Exit** → Save Changes and Exit (F10)


**Примечание:** Secure Boot отсутствует в этом BIOS — это нормально.

---