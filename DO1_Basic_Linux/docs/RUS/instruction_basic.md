# Операционные системы UNIX/Linux

## Part 1. Установка ОС
- Установили VirtualBox 
- Скачали образ Ubuntu 20.04 Server LTS без графического интерфейса
- Запустили виртуальную машину с помощью VirtualBox и установили Ubuntu 20.04 Server LTS 
![Установлен Ubuntu 20.04 Server LTS](./images/1_1_Ubuntu2004server.png)
- выполнили команду \
`cat /etc/issue` - увидили версию Ubuntu
![Проверка версии Ubuntu](./images/1_2_Check%20version%20Ubuntu.png)

## Part 2. Создание пользователя

- команды для создания пользователя \
`sudo adduser reddog` где reddog - имя пользователя

- добавление пользователя в adm группу \
`sudo usermod -aG adm reddog`
![Добавление нового пользователя reddog](./images/2_1_ADD_User_Command_VirtualBox_Ubuntu2004server_23_10_2025_11_53_52.png)

- Новый пользователь *reddog* в выводе команды \
`cat /etc/passwd`
![Вывод команды cat /etc/passwd](./images/2_2_Command_part2_VirtualBox_Ubuntu2004server_23_10_2025_11_56_26.png)

## Part 3. Настройка сети ОС

- Задаем название машины вида user-1 следующей командой \
`sudo hostnamectl set-hostname user-1`

- - Проверяем какое установилось имя \
`hostnamectl`
![Установка hostname](./images/3_1_hostname_user1_VirtualBox_Ubuntu2004server_23_10_2025_12_05_56.png)

- Установливаем временную зону, соответствующую твоему текущему местоположению \
`sudo timedatectl set-timezone Europe/Moscow`

- - Проверяем какая установилась временная зона \
`timedatectl`
![Проверка временной зоны](./images/3_2_timezone_VirtualBox_Ubuntu2004server_23_10_2025_12_13_09.png)

- Вывели названия сетевых интерфейсов с помощью консольной команды \
`ip a`

- - внутренний виртуальный интерфейс lo - loopback-интерфейс предназначена для внутренней связи системы с самой собой используется ОС, IP 127.0.0.1 localhost, программы могут общаться друг с другом по сети, не выходя наружу. Позволяет тестировать сетевые ресурсы локально.

- - физический (виртуально-физический) интерфейс enp0s8. Когда создаешь виртуальную машину, VirtualBox по умолчанию создает одну сетевую карту - enp0s3, мы добавили вторую сетевую карту Host Only как enp0s8 (как внутренняя сеть)
![Вывод сетевых интерфейсов на экран](./images/3_3_NetInterface_VirtualBox_Ubuntu2004server_23_10_2025_12_15_37.png)

- Используя консольную команду, получим ip адрес устройства, на котором работаем, от DHCP-сервера. \
`ip a | grep inet`
- - DHCP (Dynamic Host Configuration Protocol) - протокол автоматически выдает сетевые параметры:
- - - IP 10.0.2.14
- - - маска /24 (255.255.255.0)
- - - шлюз(gateway)10.0.2.2
- - - broadcast(brd) 10.0.2.255
- - - DNS
![вывод ip от DHCP](./images/3_5_IP_adress_VirtualBox_Ubuntu2004server_23_10_2025_12_18_20.png)  

- Определили и вывели на экран внешний ip-адрес шлюза (ip) \
`curl ifconfig.me` или `curl icanhazip.com`
![вывод внешний ip](./images/3_7_external_IP_VirtualBox_Ubuntu2004server_23_10_2025_12_22_36.png)

- Вывод внутренний IP-адрес шлюза, он же ip-адрес по умолчанию (gw)\
`ip route` 
![вывод gw](./images/3_6_gatewayVirtualBox_Ubuntu2004server_23_10_2025_12_19_56.png) 


- Задали статичные (заданные вручную, а не полученные от DHCP-сервера) настройки ip, gw, dns (используй публичный DNS-серверы, например 1.1.1.1 или 8.8.8.8).  \
`sudo nano /etc/netplan/00-installer-config.yaml` - открываем конфигурационный файл и в ручную прописываем ip, gw, dns. \
`sudo netplan apply` Принимаем настройки. \
![Статичный IP](./images/3_9_staticIP_VirtualBox_Ubuntu2004server_23_10_2025_13_35_24.png)

- Перезагрузили виртуальную машину. Убедись, что статичные сетевые настройки (ip, gw, dns) соответствуют заданным в предыдущем пункте. \ 
`sudo reboot` - перезагрузка ВМ.\
`ip a` - проверил ip adress.\
`ip route` - проверил gw.\

- Успешно пропингуй удаленные хосты 1.1.1.1 и ya.ru. В выводе команды должна быть фраза «0% packet loss».\
`ping 1.1.1.1 -c 4` и `ping ya.ru -c 4`
![Пингование хостов](./images/3_9_ping_VirtualBox_Ubuntu2004server_23_10_2025_13_49_37.png)

## Part 4. Обновление ОС

- Обновили системные пакеты до последней на момент выполнения задания версии. \
`sudo apt update` - обновляет список доступных пакетов.\
`sudo apt upgrade -y` - обновляет установленные пакеты до последней версии.\
![Обновление доступных пакетов](./images/4_1_update_VirtualBox_Ubuntu2004server_23_10_2025_13_55_21.png)
- Перезагрузка ВМ.\
`sudo reboot`
- После обновления системных пакетов, если ввести команду обновления повторно, должно появиться сообщение о том, что обновления отсутствуют.
![Обновление установленных пакетов](./images/4_2_upgrade_VirtualBox_Ubuntu2004server_23_10_2025_14_43_17.png)

## Part 5. Использование команды **sudo**

- Разрешили пользователю *reddog*, созданному в [Part 2](#part-2-создание-пользователя), выполнять команду sudo - добавили пользователя в группу *sudo*. \
`sudo usermod -aG sudo reddog` - После добавления в группу sudo нужно выйти и зайти под пользователем *reddog*.\
![Пользователь reddog в группе sudo](./images/5_1_sudo_VirtualBox_Ubuntu2004server_23_10_2025_15_01_41.png)
- *Истинное* назначение команды *sudo* (superuser do) - это команда, которая позволяет временно выполнять команды с правами суперпользователя *root*.
- Поменяли hostname ОС *user-1* от имени пользователя *reddog*, созданного в пункте [Part 2](#part-2-создание-пользователя) (используя *sudo*) на *User-2*.\
`sudo hostnamectl set-hostname User-2` \
`hostnamectl` проверили замену \
![Замена хостимени ОС](./images/5_2_User-2_VirtualBox_Ubuntu2004server_23_10_2025_15_18_33.png)

## Part 6. Установка и настройка службы времени

- Выводии время часового пояса, в котором сейчас находимся.\
`timedatectl`
- Настроили службу автоматической синхронизации времени и проверили. \
`timedatectl show | grep NTPSynchronized`
- Вывод следующей команды содержит `NTPSynchronized=yes` \
![Вывод времени часового пояса и службы автоматической синхронизации](./images/6_2_syncdtime_VirtualBox_Ubuntu2004server_23_10_2025_15_31_01.png)

## Part 7. Установка и использование текстовых редакторов 

- Установили текстовые редакторы **VIM** (+ любые два по желанию **NANO**, **MCEDIT**)  c помощью команды \
`sudo apt install nano vim mcedit -y`
- Проверка установленных текстовых редакторов по команде \
`which nano vim mcedit`\
![Установка текстовых редакторов](./images/7_1_VirtualBox_Ubuntu2004server_23_10_2025_16_06_08.png)

- Используя каждый из трех выбранных редакторов, создали файлы *test_X.txt*, где X — название редактора, в котором создан файл. 
- - `vim test_vim.txt` - Создали файл и произвели действия в VIM:
- - - 1 Нажали `i` (режим вставки)
- - - 2 Написали: `lorydari`
- - - 3 Нажали `Esc` (выход из режима вставки)
- - - 4 Ввели: `:wq` и нажали `Enter` (сохранить и выйти)
![Действия в VIM](./images/7_2_vim_text_VirtualBox_Ubuntu2004server_23_10_2025_16_19_29.png)

- - `nano test_nano.txt` - Создали файл и произвели действия в Nano:
- - - 1 Написали: `lorydari`
- - - 2 Нажали `Ctrl + O` (режим WriteOut - сохранить)
- - - 3 Нажали `Enter` (подтвердить имя файла)
- - - 4 Нажали `Ctrl + X` (выйти)
![Действия в NANO](./images/7_2_nano_VirtualBox_Ubuntu2004server_25_10_2025_10_03_48.png)

- - `mcedit test_mcedit.txt`
- - - 1 Написали: `lorydari`
- - - 2 Нажали `F2` (save - сохранить)
- - - 3 Нажали `F10`(выйти)
![Действия в MCEDIT](./images/7_2_3_mc_VirtualBox_Ubuntu2004server_23_10_2025_16_27_54.png)

- Используя каждый из трех выбранных редакторов, открыли файлы на редактирование, отредактировали файл, заменив никнейм на строку «21 School 21», закрыли файлы без сохранения изменений.
- - `vim test_vim.txt` - Открыли файл и произвели действия в VIM:
- - - 1 Нажали `i` (режим вставки)
- - - 2 Написали: `21 School 21`
- - - 3 Нажали `Esc` (выход из режима вставки)
- - - 4 Ввели: `:q!` и нажали `Enter` (выйти без сохранения)
![Действия в VIM](./images/7_3_vim_VirtualBox_Ubuntu2004server_23_10_2025_16_39_47.png)

- - `nano test_nano.txt` - Создали файл и произвели действия в Nano:
- - - 1 Написали: `21 School 21`
- - - 2 Нажали `Ctrl + X` (выйти)
- - - 3 На вопрос "Save modified buffer?" - Нажали`N` (NO)
![Действия в NANO](./images/7_3_nano_VirtualBox_Ubuntu2004server_23_10_2025_16_43_09.png)

- - `mcedit test_mcedit.txt`
- - - 1 Написали: `21 School 21`
- - - 2 Нажали `F10` или `Esc`(выйти)
- - - 3 На вопрос о сохранении выбрали "No"
![Действия в MCEDIT](./images/7_3_mc_VirtualBox_Ubuntu2004server_23_10_2025_16_46_29.png)

- Используя каждый из трех выбранных редакторов, отредактировали файл ещё раз вместо `lorydari` записали `21 School 21` \
- Затем освоили функции поиска по содержимому файла (слово) и замены слова `21 School 21` на `reddog`.
- - `vim test_vim.txt` - Открыли файл и произвели действия в VIM:
- - - 1 В режиме команд написали: `:%s/21 School 21/`
![Поиск слова в VIM](./images/7_4_1_vim_VirtualBox_Ubuntu2004server_23_10_2025_19_20_41.png)
- - - 2 Для вставки дополнили: `:%s/21 School 21/reddog/g`
![Вставка слова в VIM](./images/7_4_2_vim_VirtualBox_Ubuntu2004server_23_10_2025_19_22_10.png)
- - - 3 Ввели: `:wq` и нажали `Enter` (выйти и сохранить)

- - `nano test_nano.txt` - Создали файл и произвели действия в Nano:
- - - 1 Нажали `Ctrl + W` (поиск)
- - - 2 Написали: `21 School 21`
![Поиск слова в Nano](./images/7_4_1_nano_VirtualBox_Ubuntu2004server_23_10_2025_19_31_04.png)
- - - 3 Нажали `Ctrl + \` (замена)
- - - 4 Написали: `reddog`
- - - 5 Нажали `Ctrl + O` (режим WriteOut - сохранить)
- - - 6 Нажали `Enter` (подтвердить имя файла)
- - - 7 Нажали `Ctrl + X` (выйти)
![Действия в NANO](./images/7_4_2_nano_VirtualBox_Ubuntu2004server_23_10_2025_19_32_20.png)

- - `mcedit test_mcedit.txt`
- - - 1 Нажали `F7`(поиск)
- - - 2 Написали: `21 School 21`
![Действия в MCEDIT](./images/7_4_1_mc_VirtualBox_Ubuntu2004server_23_10_2025_19_38_56.png)
- - - 3 Нажали `F4` (замена)
- - - 4 Написали: `reddog`
- - - 5 Нажали `F2` (save - сохранить)
- - - 6 Нажали `F10`(выйти)
![Действия в MCEDIT](./images/7_4_2_mc_VirtualBox_Ubuntu2004server_23_10_2025_19_39_55.png)

- Проверили содержимое в редакторах
![Проверка редакторов](./images/7_4_3_all_VirtualBox_Ubuntu2004server_23_10_2025_19_44_21.png)

## Part 8. Установка и базовая настройка сервиса **SSHD**

- Установили службу SSHd: Проверили обновления`sudo apt update`, установли SSH-server`sudo apt install openssh-server -y`
![Установка SSH-server](./images/8_1_SSH_VirtualBox_Ubuntu2004server_23_10_2025_19_57_06.png) 

- Добавили автостарт службы при загрузке системы: `sudo systemctl enable ssh`
![Добавили автостарт службы](./images/8_2_avtoSSH_VirtualBox_Ubuntu2004server_23_10_2025_19_58_51.png) 

- Перенастроили службу SSHd на порт 2022. 
- - Открыли конфиг SSHD: `sudo nano /etc/ssh/sshd_config`
- - Нашли строку "Port22" и заменили на "Port2022" сохранили (Ctrl+ O) и вышли (Ctrl+ X)
- - Перезапустили службу: `sudo systemctl restart ssh`
![Перенастройка порта 22](./images/8_3_portSSH_VirtualBox_Ubuntu2004server_23_10_2025_20_01_19.png)

- Используя команду ps, показали наличие процесса sshd. Для этого к команде подобрали ключи: `ps -ef | grep sshd`
- - Команда ps - активные процессы
- - Ключ -e отобразить все процессы в системе
- - Ключ -f полный формат вывода ( с пользователями и PID)
- - | grep sshd фильтрует только строки, где упоминается sshd
![Команда ps](./images/8_4_VirtualBox_Ubuntu2004server_23_10_2025_20_04_09.png)

- Перезагрузили систему.

- Вывод команды: `sudo netstat -tan | grep 2022` должен содержать  \
`tcp 0 0 0.0.0.0:2022 0.0.0.0:* LISTEN`  \
- Если команды 'netstat' нет , установи командой `sudo apt install net-tools -y`
- Пояснения ключей и команды tan:
- - -t - показать только TCP-соединения
- - -a - показать все порты(вкл Listen)
- - -n - показать IP и порты в числовом ввиде
- - tcp 0 0 0.0.0.0:2022 - тип соединения tcp - сервер слушает все порты 0.0.0.0 на порту 2022 ; 
- - LISTEN - порт открыт и ожидает входящих подключений
![Команда tan](./images/8_5_tan_VirtualBox_Ubuntu2004server_23_10_2025_20_10_08.png)

## Part 9. Установка и использование утилит **top**, **htop**

- Установил и запустил утилиты top(procps) и htop: `sudo apt install procps htop -y`
![Установка утилиты top(procps) и htop](./images/9_1_top_htop_VirtualBox_Ubuntu2004server_23_10_2025_20_20_48.png)

- По выводу команды top определили:
  - - uptime 16 min
  - - количество авторизованных пользователей user 1,
  - - среднюю загрузку системы 0.07, 0.02, 0.00
  - - общее количество процессов, Tasks 110
  - - загрузку cpu, 0.0 us, 0.1 su, 0.0 ni, 99.9 id, остальное 0.0
  - - загрузку памяти, 3901.1 total 3088 free 159.2 used
  ![Отчет top](./images/9_2_top_VirtualBox_Ubuntu2004server_23_10_2025_20_22_20.png)
  - - pid процесса занимающего больше всего памяти `ps aus --sort=-%mem`, 427
  ![pid процесса занимающего больше всего памяти](./images/9_3_sort_mem_VirtualBox_Ubuntu2004server_23_10_2025_20_25_56.png)
  - - pid процесса, занимающего больше всего процессорного времени `ps aus --sort=-%cpu`, 721
  ![pid процесса, занимающего больше всего процессорного времени](./images/9_4_sort_cpu_VirtualBox_Ubuntu2004server_23_10_2025_20_26_39.png)

- C выводом команды htop F6(SortBy), F3(Filter), F2(Setup):
![Отчет команды htop](./images/9_5_htop_VirtualBox_Ubuntu2004server_23_10_2025_20_27_35.png)
  - - отсортированному по PID, ;
   ![Отчет](./images/9_6_htop_sortPID_VirtualBox_Ubuntu2004server_23_10_2025_20_30_04.png)
  - - отсортированному по PERCENT_CPU;
   ![Отчет](./images/9_7_sort%25CPU_VirtualBox_Ubuntu2004server_23_10_2025_20_30_40.png)
  - - отсортированному по PERCENT_MEM;
    ![Отчет](./images/9_8_sort%25Mem_VirtualBox_Ubuntu2004server_23_10_2025_20_31_27.png)
  - - отсортированному по TIME;
    ![Отчет](./images/9_9_sortTime_VirtualBox_Ubuntu2004server_23_10_2025_20_32_01.png)
 
  - - отфильтрованному для процесса sshd;
  ![Отчет](./images/9_10_sortSSHD_VirtualBox_Ubuntu2004server_23_10_2025_20_33_30.png)
  - - с процессом syslog, найденным, используя поиск;
  ![Отчет](./images/9_11_sortSyslog_VirtualBox_Ubuntu2004server_23_10_2025_20_34_18.png)
  - - F2(Setup) Meters с добавленным выводом Hostname, Clock и Uptime. 
  ![Отчет](./images/9_12_VirtualBox_Ubuntu2004server_23_10_2025_20_37_18.png)

## Part 10. Использование утилиты **fdisk**

- Запустили команду `sudo fdisk -l`.
- - название жесткого диска /dev/sda HARDDISK, его размер 25 GiB и количество секторов 52428800, а также размер swap 3.8 GiB used 0B.
![Report](./images/10_fdisk_l_VirtualBox_Ubuntu2004server_23_10_2025_20_46_55.png)
![Report](./images/10_1_swap_VirtualBox_Ubuntu2004server_25_10_2025_12_41_26.png)

## Part 11. Использование утилиты **df** 

- Запустили команду `df`.  
- В отчёте напиши для корневого раздела (/):
  - размер раздела 24541264 ,
  - размер занятого пространства 7362364 ,
  - размер свободного пространства 15906940 ,
  - процент использования 32%.
  -  в отчёте единица измерения в выводе 1K-block(1024 ,байт).
  ![Report](./images/11_1_df_VirtualBox_Ubuntu2004server_23_10_2025_20_49_44.png)  

- Запустили команду `df -Th`.
- В отчёте напиши для корневого раздела (/):
    - размер раздела 24G,
    - размер занятого пространства 7.1G,
    - размер свободного пространства 16G,
    - процент использования 32%.
    - в отчёте тип файловой системы для раздела ext4.
    ![Report](./images/11_2_df_Th_VirtualBox_Ubuntu2004server_23_10_2025_20_51_28.png)

## Part 12. Использование утилиты **du**
**== Задание ==**

- Запустили команду du.
![Report](./images/12_1_VirtualBox_Ubuntu2004server_25_10_2025_14_21_02.png)
- Вывели размер папок /home, /var, /var/log (в байтах, в человекочитаемом виде) `sudo du -sh /home /var /var/log`
![Report](./images/12_2_du-sh_VirtualBox_Ubuntu2004server_25_10_2025_14_28_23.png)

- Выведи размер всего содержимого в /var/log (не общее, а каждого вложенного элемента, используя *), \
`sudo du -sh /var/log/* | sort -hr`человеко читаемой ввиде \ и в байтах `sudo du -sh /var/log/* | sort -nr | head -n 30`
![Report](./images/12_3_var:log_VirtualBox_Ubuntu2004server_25_10_2025_14_34_00.png)
![Report](./images/12_3_var:log_B_top30_VirtualBox_Ubuntu2004server_25_10_2025_14_34_35.png)

## Part 13. Установка и использование утилиты **ncdu**

- Установи утилиту ncdu.
![Report](./images/13_1_ncdu_VirtualBox_Ubuntu2004server_25_10_2025_14_42_53.png)
- Выведи размер папок /home, /var, /var/log.
![Report](./images/13_2_:home_VirtualBox_Ubuntu2004server_25_10_2025_14_44_32.png)
![Report](./images/13_2_:var_VirtualBox_Ubuntu2004server_25_10_2025_14_45_19.png)
![Report](./images/13_2_:var:log_VirtualBox_Ubuntu2004server_25_10_2025_14_45_59.png)
- Размеры примерно совпадают с полученными в [Part 12](#part-12-использование-утилиты-du).

## Part 14. Работа с системными журналами

- Открыли для просмотра:
- - 1. /var/log/dmesg
![Report](./images/14_1_VirtualBox_Ubuntu2004server_25_10_2025_15_02_27.png)
- - 2. /var/log/syslog
![Report](./images/14_2_VirtualBox_Ubuntu2004server_25_10_2025_15_03_29.png)
- - 3. /var/log/auth.log
![Report](./images/14_3_VirtualBox_Ubuntu2004server_25_10_2025_15_03_58.png)  

- отчёт время последней успешной авторизации, имя пользователя и метод входа в систему.
![Report](./images/14_4_VirtualBox_Ubuntu2004server_25_10_2025_15_05_46.png)
![Report](./images/14_5_VirtualBox_Ubuntu2004server_25_10_2025_15_07_32.png)
- Перезапустили службу SSHd.`sudo systemctl restart sshd`
- отчёт скрин с сообщением о рестарте службы (искать в логах).
![Report](./images/14_6_VirtualBox_Ubuntu2004server_25_10_2025_15_12_16.png)


## Part 15. Использование планировщика заданий **CRON**

- Открыли редактор crontab
`crontab -e`
![Report](./images/15_1_nano_VirtualBox_Ubuntu2004server_25_10_2025_18_23_45.png)
- Используя планировщик заданий, запустили команду uptime через каждые 2 минуты.
`sudo systemctl status cron`
![Report](./images/15_2_Cron_VirtualBox_Ubuntu2004server_25_10_2025_18_26_38.png)
- Найди в системных журналах строчки (минимум две в заданном временном диапазоне) о выполнении.
`cat /home/lorydari/uptime.log`
![Report](./images/15_3_Task_VirtualBox_Ubuntu2004server_25_10_2025_19_03_20.png) \
- Выведи на экран список текущих заданий для CRON.
`crontab -l`
![Report](./images/15-4_VirtualBox_Ubuntu2004server_25_10_2025_19_04_15.png)
- Вставь в отчёт скрины со строчками о выполнении и списком текущих задач.
`sudo grep CRON /var/log/syslog | tail -n 10`
![Report](./images/15_5_VirtualBox_Ubuntu2004server_25_10_2025_19_07_33.png)

- Удали все задания из планировщика заданий.
`crontab -r`
- В отчёт вставь скрин со списком текущих заданий для CRON.
`crontab -l`
![Report](./images/15_6_VirtualBox_Ubuntu2004server_25_10_2025_19_09_32.png)




