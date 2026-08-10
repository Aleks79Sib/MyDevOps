# Начало пути в Devops

## Введение

Открываем серию проектов в DevOps от простого к сложному , от теории к практики

все проекты будут выполняться на OS Linux - развертывания виртаульных машин и домашнего сервера

## Часть 1: Установка ОС

### 1.1 Выбор среды для установки ОС

для обычных тренировок и получение навыков можно использовать Виртаульную машину (VM)
в зависимости какое у вас железо и OS (Mac , Windows, Linux) можно выбрать любого правайдера для установки на вашем компьютере

1 [Multipass](https://canonical.com/multipass/docs/latest/how-to-guides/install-multipass/)

2 [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

3 [Libvirt]()https://libvirt.org/downloads.html

4 Можете арендовать VPS на облаке с предустановкой ОС -самый простой , но не бесплатный вариант

5 Можете на голое железо установить ОС с помощью загрузочного диска или флэшки USB 

### 1.2 Multipass

Пример развертывания Виртуальной машины на macOS найдете в [инструкции](./docs/RUS/multipass.md) или [официальной документации Multipass](https://canonical.com/multipass/docs/latest/how-to-guides/install-multipass/)


### 1.3 VirtualBox

Пример развертывания Виртуальной машины на VirtualBox
найдете в [инструкции](./docs/RUS/virtualbox.md) или [официальной документации VB](https://www.virtualbox.org/manual/topics/installation.html#installation)

### 1.4 Установка ОС на "голое железо"

#### 1.4.1 Подготовка установочных дисков 

вы можете создать загрузочную usb flesh или создать мультизагрузочную usb flesh

- Подготовка [загрузочной usb flesh](./docs/RUS/002_install_with_usb.md)

- Подготовка [мультизагрузочной usb flesh](https://sourceforge.net/projects/ventoy/files/v1.1.16/)


#### 1.4.1 Установка ОС

- установим ОС с помощью [инструкции](./docs/RUS/02-install-ubuntu.md)


## Часть 2: Базовые команды и настройка OS Linux

**Операционные системы UNIX/Linux**

### 2.1 Установлена ОС

- Установлена ОС

![Установлен Ubuntu 20.04 Server LTS](../DO1_Basic_Linux/docs/screenshots/basic_commands/1_1_Ubuntu2004server.png)

- выполнили команду 

`cat /etc/issue` - увидили версию Ubuntu

![Проверка версии Ubuntu](../DO1_Basic_Linux/docs/screenshots/basic_commands/1_2_Check%20version%20Ubuntu.png)

### 2.2. Создание пользователя

- команды для создания пользователя

```bash
sudo adduser reddog
``` 
где `reddog` - имя пользователя

- добавление пользователя в adm группу

```bash
sudo usermod -aG adm reddog
```

![Добавление нового пользователя reddog](../DO1_Basic_Linux/docs/screenshots/basic_commands/2_1_ADD_User_Command_VirtualBox_Ubuntu2004server_23_10_2025_11_53_52.png)

- Новый пользователь *reddog* в выводе команды

```bash
cat /etc/passwd
```

![Вывод команды cat /etc/passwd](../DO1_Basic_Linux/docs/screenshots/basic_commands/2_2_Command_part2_VirtualBox_Ubuntu2004server_23_10_2025_11_56_26.png)

### 2.3. Настройка сети ОС

- Задаем название машины вида user-1 следующей командой

```bash
sudo hostnamectl set-hostname user-1
```

- Проверяем какое установилось имя

```bash
hostnamectl
```

![Установка hostname](../DO1_Basic_Linux/docs/screenshots/basic_commands/3_1_hostname_user1_VirtualBox_Ubuntu2004server_23_10_2025_12_05_56.png)

- Установливаем временную зону, соответствующую твоему текущему местоположению

```bash
sudo timedatectl set-timezone Europe/Moscow
```

- Проверяем какая установилась временная зона

```bash
timedatectl
```

![Проверка временной зоны](../DO1_Basic_Linux/docs/screenshots/basic_commands/3_2_timezone_VirtualBox_Ubuntu2004server_23_10_2025_12_13_09.png)

- Вывели названия сетевых интерфейсов с помощью консольной команды

```bash
ip a
```

- внутренний виртуальный интерфейс `lo` - loopback-интерфейс предназначена для внутренней связи системы с самой собой используется ОС, IP 127.0.0.1 localhost, программы могут общаться друг с другом по сети, не выходя наружу. Позволяет тестировать сетевые ресурсы локально.

- физический (виртуально-физический) интерфейс `enp0s8`. Когда создаешь виртуальную машину, VirtualBox по умолчанию создает одну сетевую карту - enp0s3, мы добавили вторую сетевую карту Host Only как enp0s8 (как внутренняя сеть)

![Вывод сетевых интерфейсов на экран](../DO1_Basic_Linux/docs/screenshots/basic_commands/3_3_NetInterface_VirtualBox_Ubuntu2004server_23_10_2025_12_15_37.png)

- Используя консольную команду, получим ip адрес устройства, на котором работаем, от DHCP-сервера.

```bash
ip a | grep inet
```

DHCP (Dynamic Host Configuration Protocol) - протокол автоматически выдает сетевые параметры:
- IP 10.0.2.14
- маска /24 (255.255.255.0)
- шлюз(gateway)10.0.2.2
- broadcast(brd) 10.0.2.255
- DNS

![вывод ip от DHCP](../DO1_Basic_Linux/docs/screenshots/basic_commands/3_5_IP_adress_VirtualBox_Ubuntu2004server_23_10_2025_12_18_20.png)  

- Определили и вывели на экран внешний ip-адрес шлюза (ip)

```bash
curl ifconfig.me
# или `curl icanhazip.com`
```

![вывод внешний ip](../DO1_Basic_Linux/docs/screenshots/basic_commands/3_7_external_IP_VirtualBox_Ubuntu2004server_23_10_2025_12_22_36.png)

- Вывод внутренний IP-адрес шлюза, он же ip-адрес по умолчанию (gw)

```bash
ip route
```

![вывод gw](../DO1_Basic_Linux/docs/screenshots/basic_commands/3_6_gatewayVirtualBox_Ubuntu2004server_23_10_2025_12_19_56.png) 


- Задали статичные (заданные вручную, а не полученные от DHCP-сервера) настройки ip, gw, dns (используй публичный DNS-серверы, например 1.1.1.1 или 8.8.8.8).

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

- открываем конфигурационный файл и в ручную прописываем ip, gw, dns. 

```bash
sudo netplan apply
```
Принимаем настройки.

![Статичный IP](../DO1_Basic_Linux/docs/screenshots/basic_commands/3_9_staticIP_VirtualBox_Ubuntu2004server_23_10_2025_13_35_24.png)

- Перезагрузили виртуальную машину. Убедись, что статичные сетевые настройки (ip, gw, dns) соответствуют заданным в предыдущем пункте.

```bash
`sudo reboot` #- перезагрузка ВМ.
`ip a` #- проверил ip adress.
`ip route` #- проверил gw.
```

- Успешно пропингуй удаленные хосты `1.1.1.1 и ya.ru`. В выводе команды должна быть фраза `0% packet loss`.

```bash
`ping 1.1.1.1 -c 4`
`ping ya.ru -c 4`
```

![Пингование хостов](../DO1_Basic_Linux/docs/screenshots/basic_commands/3_9_ping_VirtualBox_Ubuntu2004server_23_10_2025_13_49_37.png)

### 2.4. Обновление ОС

- Обновили системные пакеты до последней на момент выполнения задания версии.

```bash
sudo apt update
```
- обновляет список доступных пакетов.

```bash
sudo apt upgrade -y
```
- обновляет установленные пакеты до последней версии.

![Обновление доступных пакетов](../DO1_Basic_Linux/docs/screenshots/basic_commands/4_1_update_VirtualBox_Ubuntu2004server_23_10_2025_13_55_21.png)

- Перезагрузка ВМ.

```bash
sudo reboot
```

- После обновления системных пакетов, если ввести команду обновления повторно, должно появиться сообщение о том, что обновления отсутствуют.

![Обновление установленных пакетов](../DO1_Basic_Linux/docs/screenshots/basic_commands/4_2_upgrade_VirtualBox_Ubuntu2004server_23_10_2025_14_43_17.png)

### 2.5. Использование команды **sudo**

- Разрешили пользователю *reddog*, созданному в [2.2](#22-создание-пользователя), выполнять команду sudo - добавили пользователя в группу *sudo*.

```bash
sudo usermod -aG sudo reddog
```
- После добавления в группу sudo нужно выйти и зайти под пользователем *reddog*.

![Пользователь reddog в группе sudo](../DO1_Basic_Linux/docs/screenshots/basic_commands/5_1_sudo_VirtualBox_Ubuntu2004server_23_10_2025_15_01_41.png)

- *Истинное* назначение команды *sudo* (superuser do) - это команда, которая позволяет временно выполнять команды с правами суперпользователя *root*.

- Поменяли hostname ОС *user-1* от имени пользователя *reddog*, созданного в пункте [2.2](#22-создание-пользователя)(используя *sudo*) на *User-2*.

```bash
sudo hostnamectl set-hostname User-2
```
```bash
hostnamectl
``` 
- проверили замену

![Замена хостимени ОС](../DO1_Basic_Linux/docs/screenshots/basic_commands/5_2_User-2_VirtualBox_Ubuntu2004server_23_10_2025_15_18_33.png)

### 2.6. Установка и настройка службы времени

- Выводии время часового пояса, в котором сейчас находимся.

```bash
timedatectl
```

- Настроили службу автоматической синхронизации времени и проверили.

```bash
timedatectl show | grep NTPSynchronized
```

- Вывод следующей команды содержит `NTPSynchronized=yes`

![Вывод времени часового пояса и службы автоматической синхронизации](../DO1_Basic_Linux/docs/screenshots/basic_commands/6_2_syncdtime_VirtualBox_Ubuntu2004server_23_10_2025_15_31_01.png)

### 2.7. Установка и использование текстовых редакторов 

- Установили текстовые редакторы **VIM** (+ любые два по желанию **NANO**, **MCEDIT**)  c помощью команды:

```bash
sudo apt install nano vim mcedit -y
```

- Проверка установленных текстовых редакторов по команде:

```bash
which nano vim mcedit
```

![Установка текстовых редакторов](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_1_VirtualBox_Ubuntu2004server_23_10_2025_16_06_08.png)

- Используя каждый из трех выбранных редакторов, создали файлы *test_X.txt*, где X — название редактора, в котором создан файл. 

```bash
vim test_vim.txt #- Создали файл и произвели действия в VIM:
```
- 1 Нажали `i` (режим вставки)
- 2 Написали: `lorydari`
- 3 Нажали `Esc` (выход из режима вставки)
- 4 Ввели: `:wq` и нажали `Enter` (сохранить и выйти)

![Действия в VIM](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_2_vim_text_VirtualBox_Ubuntu2004server_23_10_2025_16_19_29.png)

```bash
nano test_nano.txt` #- Создали файл и произвели действия в Nano:
```
- 1 Написали: `lorydari`
- 2 Нажали `Ctrl + O` (режим WriteOut - сохранить)
- 3 Нажали `Enter` (подтвердить имя файла)
- 4 Нажали `Ctrl + X` (выйти)

![Действия в NANO](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_2_nano_VirtualBox_Ubuntu2004server_25_10_2025_10_03_48.png)

```bash
mcedit test_mcedit.txt
```

- 1 Написали: `lorydari`
- 2 Нажали `F2` (save - сохранить)
- 3 Нажали `F10`(выйти)

![Действия в MCEDIT](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_2_3_mc_VirtualBox_Ubuntu2004server_23_10_2025_16_27_54.png)

- Используя каждый из трех выбранных редакторов, открыли файлы на редактирование, отредактировали файл, заменив никнейм на строку «21 School 21», закрыли файлы без сохранения изменений.

- `vim test_vim.txt` - Открыли файл и произвели действия в VIM:
- 1 Нажали `i` (режим вставки)
- 2 Написали: `21 School 21`
- 3 Нажали `Esc` (выход из режима вставки)
- 4 Ввели: `:q!` и нажали `Enter` (выйти без сохранения)

![Действия в VIM](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_3_vim_VirtualBox_Ubuntu2004server_23_10_2025_16_39_47.png)

- `nano test_nano.txt` - Создали файл и произвели действия в Nano:
- 1 Написали: `21 School 21`
- 2 Нажали `Ctrl + X` (выйти)
- 3 На вопрос "Save modified buffer?" - Нажали`N` (NO)

![Действия в NANO](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_3_nano_VirtualBox_Ubuntu2004server_23_10_2025_16_43_09.png)

- `mcedit test_mcedit.txt`
- 1 Написали: `21 School 21`
- 2 Нажали `F10` или `Esc`(выйти)
- 3 На вопрос о сохранении выбрали "No"

![Действия в MCEDIT](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_3_mc_VirtualBox_Ubuntu2004server_23_10_2025_16_46_29.png)

- Используя каждый из трех выбранных редакторов, отредактировали файл ещё раз вместо `lorydari` записали `21 School 21` \
- Затем освоили функции поиска по содержимому файла (слово) и замены слова `21 School 21` на `reddog`.
- `vim test_vim.txt` - Открыли файл и произвели действия в VIM:
- 1 В режиме команд написали: `:%s/21 School 21/`

![Поиск слова в VIM](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_4_1_vim_VirtualBox_Ubuntu2004server_23_10_2025_19_20_41.png)

- 2 Для вставки дополнили: `:%s/21 School 21/reddog/g`

![Вставка слова в VIM](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_4_2_vim_VirtualBox_Ubuntu2004server_23_10_2025_19_22_10.png)

- 3 Ввели: `:wq` и нажали `Enter` (выйти и сохранить)

- `nano test_nano.txt` - Создали файл и произвели действия в Nano:
- 1 Нажали `Ctrl + W` (поиск)
- 2 Написали: `21 School 21`

![Поиск слова в Nano](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_4_1_nano_VirtualBox_Ubuntu2004server_23_10_2025_19_31_04.png)

- 3 Нажали `Ctrl + \` (замена)
- 4 Написали: `reddog`
- 5 Нажали `Ctrl + O` (режим WriteOut - сохранить)
- 6 Нажали `Enter` (подтвердить имя файла)
- 7 Нажали `Ctrl + X` (выйти)

![Действия в NANO](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_4_2_nano_VirtualBox_Ubuntu2004server_23_10_2025_19_32_20.png)

- `mcedit test_mcedit.txt`
- 1 Нажали `F7`(поиск)
- 2 Написали: `21 School 21`

![Действия в MCEDIT](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_4_1_mc_VirtualBox_Ubuntu2004server_23_10_2025_19_38_56.png)

- 3 Нажали `F4` (замена)
- 4 Написали: `reddog`
- 5 Нажали `F2` (save - сохранить)
- 6 Нажали `F10`(выйти)

![Действия в MCEDIT](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_4_2_mc_VirtualBox_Ubuntu2004server_23_10_2025_19_39_55.png)

- Проверили содержимое в редакторах
![Проверка редакторов](../DO1_Basic_Linux/docs/screenshots/basic_commands/7_4_3_all_VirtualBox_Ubuntu2004server_23_10_2025_19_44_21.png)

### 2.8. Установка и базовая настройка сервиса **SSHD**

- Установили службу SSHd: Проверили обновления

```bash
sudo apt update
# установли SSH-server
sudo apt install openssh-server -y
```

![Установка SSH-server](../DO1_Basic_Linux/docs/screenshots/basic_commands/8_1_SSH_VirtualBox_Ubuntu2004server_23_10_2025_19_57_06.png) 

- Добавили автостарт службы при загрузке системы: 

```bash
sudo systemctl enable ssh
```

![Добавили автостарт службы](../DO1_Basic_Linux/docs/screenshots/basic_commands/8_2_avtoSSH_VirtualBox_Ubuntu2004server_23_10_2025_19_58_51.png) 

- Перенастроили службу SSHd на порт 2022. 
- Открыли конфиг SSHD: 

```bash
sudo nano /etc/ssh/sshd_config
```
- Нашли строку "Port22" и заменили на "Port2022" сохранили (Ctrl+ O) и вышли (Ctrl+ X)

- Перезапустили службу: 

```bash
sudo systemctl restart ssh
```

![Перенастройка порта 22](../DO1_Basic_Linux/docs/screenshots/basic_commands/8_3_portSSH_VirtualBox_Ubuntu2004server_23_10_2025_20_01_19.png)

- Используя команду ps, показали наличие процесса sshd. Для этого к команде подобрали ключи: 

```bash
ps -ef | grep sshd
```

- Команда ps - активные процессы
- Ключ -e отобразить все процессы в системе
- Ключ -f полный формат вывода ( с пользователями и PID)
- | grep sshd фильтрует только строки, где упоминается sshd

![Команда ps](../DO1_Basic_Linux/docs/screenshots/basic_commands/8_4_VirtualBox_Ubuntu2004server_23_10_2025_20_04_09.png)

- Перезагрузили систему.

- Вывод команды: 

```bash
sudo netstat -tan | grep 2022
```
должен содержать
`tcp 0 0 0.0.0.0:2022 0.0.0.0:* LISTEN`

- Если команды 'netstat' нет , установи командой 

```bash
sudo apt install net-tools -y
```

- Пояснения ключей и команды tan:
-t - показать только TCP-соединения
-a - показать все порты(вкл Listen)
-n - показать IP и порты в числовом ввиде

- tcp 0 0 0.0.0.0:2022 - тип соединения tcp - сервер слушает все порты 0.0.0.0 на порту 2022 ; 
- LISTEN - порт открыт и ожидает входящих подключений

![Команда tan](../DO1_Basic_Linux/docs/screenshots/basic_commands/8_5_tan_VirtualBox_Ubuntu2004server_23_10_2025_20_10_08.png)

### 2.9. Установка и использование утилит **top**, **htop**

- Установил и запустил утилиты top(procps) и htop: 

```bash
sudo apt install procps htop -y
```

![Установка утилиты top(procps) и htop](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_1_top_htop_VirtualBox_Ubuntu2004server_23_10_2025_20_20_48.png)

- По выводу команды top определили:
  - uptime 16 min
  - количество авторизованных пользователей user 1,
  - среднюю загрузку системы 0.07, 0.02, 0.00
  - общее количество процессов, Tasks 110
  - загрузку cpu, 0.0 us, 0.1 su, 0.0 ni, 99.9 id, остальное 0.0
  - загрузку памяти, 3901.1 total 3088 free 159.2 used

  ![Отчет top](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_2_top_VirtualBox_Ubuntu2004server_23_10_2025_20_22_20.png)

  - pid процесса занимающего больше всего памяти `ps aus --sort=-%mem`, 427

  ![pid процесса занимающего больше всего памяти](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_3_sort_mem_VirtualBox_Ubuntu2004server_23_10_2025_20_25_56.png)

  - pid процесса, занимающего больше всего процессорного времени `ps aus --sort=-%cpu`, 721

  ![pid процесса, занимающего больше всего процессорного времени](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_4_sort_cpu_VirtualBox_Ubuntu2004server_23_10_2025_20_26_39.png)

- C выводом команды htop F6(SortBy), F3(Filter), F2(Setup):

![Отчет команды htop](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_5_htop_VirtualBox_Ubuntu2004server_23_10_2025_20_27_35.png)

  - отсортированному по PID;

   ![Отчет](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_6_htop_sortPID_VirtualBox_Ubuntu2004server_23_10_2025_20_30_04.png)

  - отсортированному по PERCENT_CPU;

   ![Отчет](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_7_sort%25CPU_VirtualBox_Ubuntu2004server_23_10_2025_20_30_40.png)

  - отсортированному по PERCENT_MEM;

    ![Отчет](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_8_sort%25Mem_VirtualBox_Ubuntu2004server_23_10_2025_20_31_27.png)

  - отсортированному по TIME;

    ![Отчет](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_9_sortTime_VirtualBox_Ubuntu2004server_23_10_2025_20_32_01.png)
 
  - отфильтрованному для процесса sshd;

  ![Отчет](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_10_sortSSHD_VirtualBox_Ubuntu2004server_23_10_2025_20_33_30.png)

  - с процессом syslog, найденным, используя поиск;

  ![Отчет](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_11_sortSyslog_VirtualBox_Ubuntu2004server_23_10_2025_20_34_18.png)

  - F2(Setup) Meters с добавленным выводом Hostname, Clock и Uptime. 

  ![Отчет](../DO1_Basic_Linux/docs/screenshots/basic_commands/9_12_VirtualBox_Ubuntu2004server_23_10_2025_20_37_18.png)

### 2.10. Использование утилиты **fdisk**

- Запустили команду

```bash
sudo fdisk -l
```

- название жесткого диска /dev/sda HARDDISK, его размер 25 GiB и количество секторов 52428800, а также размер swap 3.8 GiB used 0B.

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/10_fdisk_l_VirtualBox_Ubuntu2004server_23_10_2025_20_46_55.png)

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/10_1_swap_VirtualBox_Ubuntu2004server_25_10_2025_12_41_26.png)

### 2.11. Использование утилиты **df** 

- Запустили команду

```bash
df
```

- В отчёте напиши для корневого раздела (/):
  - размер раздела 24541264 ,
  - размер занятого пространства 7362364 ,
  - размер свободного пространства 15906940 ,
  - процент использования 32%.
  - единица измерения в выводе 1K-block(1024 ,байт).

  ![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/11_1_df_VirtualBox_Ubuntu2004server_23_10_2025_20_49_44.png)  

- Запустили команду 

```bash
df -Th
```

- для корневого раздела (/):
    - размер раздела 24G,
    - размер занятого пространства 7.1G,
    - размер свободного пространства 16G,
    - процент использования 32%.
    - тип файловой системы для раздела ext4.

    ![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/11_2_df_Th_VirtualBox_Ubuntu2004server_23_10_2025_20_51_28.png)

### 2.12. Использование утилиты **du**

- Запустили команду 

```bash
du
```

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/12_1_VirtualBox_Ubuntu2004server_25_10_2025_14_21_02.png)

- Вывели размер папок /home, /var, /var/log (в байтах, в человекочитаемом виде) 

```bash
sudo du -sh /home /var /var/log
```

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/12_2_du-sh_VirtualBox_Ubuntu2004server_25_10_2025_14_28_23.png)

- Выведи размер всего содержимого в /var/log (не общее, а каждого вложенного элемента, используя *)

```bash
sudo du -sh /var/log/* | sort -hr # в человеко читаемой ввиде
```
- в байтах 
```bash
sudo du -sh /var/log/* | sort -nr | head -n 30
```

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/12_3_var:log_VirtualBox_Ubuntu2004server_25_10_2025_14_34_00.png)

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/12_3_var:log_B_top30_VirtualBox_Ubuntu2004server_25_10_2025_14_34_35.png)

### 2.13. Установка и использование утилиты **ncdu**

- Установи утилиту ncdu.

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/13_1_ncdu_VirtualBox_Ubuntu2004server_25_10_2025_14_42_53.png)

- Выведи размер папок /home, /var, /var/log.

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/13_2_:home_VirtualBox_Ubuntu2004server_25_10_2025_14_44_32.png)

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/13_2_:var_VirtualBox_Ubuntu2004server_25_10_2025_14_45_19.png)

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/13_2_:var:log_VirtualBox_Ubuntu2004server_25_10_2025_14_45_59.png)

- Размеры примерно совпадают с полученными в [в части 2.12](#212-использование-утилиты-du).

### 2.14. Работа с системными журналами

Открыли для просмотра:

- /var/log/dmesg

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/14_1_VirtualBox_Ubuntu2004server_25_10_2025_15_02_27.png)

- /var/log/syslog

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/14_2_VirtualBox_Ubuntu2004server_25_10_2025_15_03_29.png)

- /var/log/auth.log

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/14_3_VirtualBox_Ubuntu2004server_25_10_2025_15_03_58.png)  

- отчёт время последней успешной авторизации, имя пользователя и метод входа в систему.

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/14_4_VirtualBox_Ubuntu2004server_25_10_2025_15_05_46.png)

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/14_5_VirtualBox_Ubuntu2004server_25_10_2025_15_07_32.png)

- Перезапустили службу SSHd

```bash
sudo systemctl restart sshd
```

- отчёт скрин с сообщением о рестарте службы (искать в логах).

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/14_6_VirtualBox_Ubuntu2004server_25_10_2025_15_12_16.png)


### 2.15. Использование планировщика заданий **CRON**

- Открыли редактор crontab

```bash
crontab -e
```

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/15_1_nano_VirtualBox_Ubuntu2004server_25_10_2025_18_23_45.png)

- Используя планировщик заданий, запустили команду uptime через каждые 2 минуты.

```bash
sudo systemctl status cron
```

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/15_2_Cron_VirtualBox_Ubuntu2004server_25_10_2025_18_26_38.png)

- Найди в системных журналах строчки (минимум две в заданном временном диапазоне) о выполнении.

```bash
cat /home/lorydari/uptime.log
```

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/15_3_Task_VirtualBox_Ubuntu2004server_25_10_2025_19_03_20.png)

- Выведи на экран список текущих заданий для CRON.

```bash
crontab -l
```

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/15-4_VirtualBox_Ubuntu2004server_25_10_2025_19_04_15.png)

- выполнение и список текущих задач

```bash
sudo grep CRON /var/log/syslog | tail -n 10
```

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/15_5_VirtualBox_Ubuntu2004server_25_10_2025_19_07_33.png)

- Удали все задания из планировщика заданий

```bash
crontab -r
```

- список текущих заданий для CRON

```bash
crontab -l
```

![Report](../DO1_Basic_Linux/docs/screenshots/basic_commands/15_6_VirtualBox_Ubuntu2004server_25_10_2025_19_09_32.png)




