# 💽 Работа с дисками
---

## 1. Проверка диска (S.M.A.R.T.)

```bash
lsblk
# ⚠️ ВАЖНО:
# Должны быть видны /dev/sda и /dev/sdb без разделов (или с разделами, если уже использовались)

`sda           8:0    0   1.8T  0 disk`
`sdb           8:16   0   1.8T  0 disk`

# Установить smartmontools
sudo apt install smartmontools -y

# Информация о диске
sudo smartctl -a /dev/sdb

# Короткий тест (2 минуты)
sudo smartctl -t short /dev/sdb
# Посмотреть результат через 2 минуты:
sudo smartctl -l selftest /dev/sdb
```

**На что обратить внимание:**
- `SMART overall-health self-assessment test result: PASSED`
- `Reallocated_Sector_Ct` — 0 (иначе диск переназначал сектора)
- `Current_Pending_Sector` — 0 (иначе есть битые сектора)

---

## 2. Проверка поверхности

```bash
# Только чтение (без записи!)
sudo badblocks -sv /dev/sdb
```

> Если появляются `read error` — диск физически повреждён.

---

## 3. Установка необходимых пакетов для работы с дисками

```bash
sudo apt update
sudo apt install mdadm parted -y
```
- `mdadm – для управления программным RAID.`

- `parted – для создания разделов.`

## 4. Очистка дисков от старых метаданных

```bash
sudo wipefs -a /dev/sda
sudo wipefs -a /dev/sdb
```

- `Удаляет все существующие файловые системы, таблицы разделов и RAID-суперблоки.`

**Важно:** все данные на дисках будут потеряны

## 5. Создание разделов для каждого диска

`Создание разделов на каждом диске (GPT + один раздел на весь диск)`

```bash
#  Создание разделов для sda
sudo parted /dev/sda mklabel gpt
sudo parted /dev/sda mkpart primary 0% 100%
sudo parted /dev/sda set 1 raid on

# Создание разделов на втором диске
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary 0% 100%
sudo parted /dev/sdb set 1 raid on
```

Создаётся таблица разделов GPT и один раздел на весь диск, помеченный как RAID.

Проверить: lsblk покажет sda1 и sdb1.

## Создание массива RAID 1

```bash
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1

cat /proc/mdstat
```
На вопрос о битовой карте (write-intent bitmap) ответить y (ускоряет восстановление).

Предупреждение о метаданных в начале диска игнорируем (мы не загружаемся с этого RAID).






## 7. Создание файловойсистемы и Монтирование диска

```bash
sudo mkfs.ext4 /dev/md0

# Выираем -y

# Посмотреть подключённые диски
sudo lsblk
sudo fdisk -l

# Создать точки монтирования
sudo mkdir -p /storage

# Примонтировать разделы
sudo mount /dev/md0 /storage

# Проверить
df -h /storage

df -h | grep sdb
```

---

## 8. Автомонтирование (fstab)

```bash
# Узнать UUID разделов
sudo blkid /dev/md0
# (запомните вывод, например UUID="48528881-...")

# Отредактировать fstab
sudo nano /etc/fstab

# Добавить строку (используйте либо UUID, либо /dev/md0):
```

Добавить строки:

```text
UUID=... /data ext4 defaults,noatime 0 2
UUID=... /var/lib/docker ext4 defaults,noatime 0 2
/dev/md0  /storage  ext4  defaults  0  2
```

```bash
sudo systemctl daemon-reload
# Проверить без перезагрузки
sudo mount -a

# Проверить, что смонтировалось
df -h
```

---

## 9. Сохранение конфигурации RAID для автоматической сборки при старте

```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
```

- Первая команда добавляет запись о массиве в конфиг.

- Вторая – обновляет образ начальной загрузки, чтобы ядро знало о RAID на раннем этапе.

## 10. Настройка прав доступа и создание папок

```bash
sudo chown YOUR_USER:YOUR_Groups /storage
sudo chmod 775 /storage
sudo chmod g+s /storage

# - g+s – setgid бит: все новые файлы и папки внутри /storage унаследуют группу docker.

```

---

## 11. Полезные команды

```bash
# Список дисков
lsblk
sudo fdisk -l

# UUID разделов
sudo blkid

# Использование дискового пространства
df -h

# Информация о диске
sudo smartctl -a /dev/sda

# Диагностика нагрева (если диск греется)
sudo dmesg -w

# Проверить
ls -la /storage

# Посмотреть детали массива:
sudo mdadm --detail /dev/md0

# Проверить статус синхронизации:
cat /proc/mdstat

# копирование данных
sudo rsync -av --progress /path/to/old/data/ /storage/

# Или локально
sudo cp -a /path/to/old/data/* /storage/
```
