#!/bin/bash

# Функция для преобразования CIDR в маску с точками
cidr_to_mask() {
    local cidr=$1
    local mask=""
    local full_octets=$((cidr / 8))
    local partial_octet=$((cidr % 8))
    
    for i in {1..4}; do
        if [ $i -le $full_octets ]; then
            mask+="255"
        elif [ $i -eq $((full_octets + 1)) ] && [ $partial_octet -gt 0 ]; then
            mask+=$((256 - (256 >> partial_octet)))
        else
            mask+="0"
        fi
        
        if [ $i -lt 4 ]; then
            mask+="."
        fi
    done
    
    echo "$mask"
}

# Функция для получения информации о системе
get_system_info() {
    # HOSTNAME - сетевое имя компьютера
    hostname=$(hostname)

    # TIMEZONE - часовой пояс в формате America/New_York UTC -5
    timezone=$(cat /etc/timezone)
    utc_offset=$(date +%z | cut -c1,3)

    # USER - текущий пользователь, запустивший скрипт
    user=$(whoami)

    # OS - тип и версия операционной системы
    os=$(awk -F\" '/PRETTY_NAME/{print $2; exit}' /etc/os-release)

    # DATE - текущее время в формате 12 May 2020 12:24:36
    date=$(date "+%d %B %Y %H:%M:%S")

    # UPTIME - время работы системы
    uptime=$(uptime -p)

    # UPTIME_SEC - время работы системы в секундах
    uptime_sec=$(cut -d '.' -f 1 /proc/uptime)
    #uptime_sec=$(awk '{print $1}' /proc/uptime)

    # Находим сетевой интерфейс, который подключен к Интернету
    nat_interface=$(ip route | grep default | awk '{print $5; exit}')
    
    # Находим полностью конкретный IP с маской
    ip_addr=$(ip -4 -o addr show dev "$nat_interface" 2>/dev/null | awk '{print $4}')
    if [ -z "$ip_addr" ]; then
        echo "ОШИБКА: Интерфейс $nat_interface не имеет IPv4 адреса" >&2
        exit 1
    fi
    # IP - IP-адрес компьютера на любом из сетевых интерфейсов без маски
    ip="${ip_addr%/*}"
    # CIDR - маска сети цифровое значение
    cidr="${ip_addr#*/}"
    # Используем функцию из functions.sh
    mask_dots=$(cidr_to_mask $cidr)

    # GATEWAY - IP-адрес шлюза по умолчанию
    gateway=$(ip route | grep default | awk '{print $3}')

    # RAM_TOTAL - общий объем оперативной памяти в ГБ с точностью до трех знаков после запятой
    ram_total=$(free -b | grep Mem | awk '{printf "%.3f GB", $2/1073741824}')
    # RAM_USED - используемый объем памяти в ГБ с точностью до трех знаков после запятой
    ram_used=$(free -b | grep Mem | awk '{printf "%.3f GB", $3/1073741824}')

    # RAM_FREE - свободный объем памяти в ГБ с точностью до трех знаков после запятой
    ram_free=$(free -b | grep Mem | awk '{printf "%.3f GB", $7/1073741824}')

    # SPACE_ROOT - размер корневого раздела в МБ с точностью до двух знаков после запятой
    space_root=$(df -BM / | awk 'NR==2 {printf "%.2f MB", $2+0}')

    # SPACE_ROOT_USED - размер использованного пространства корневого раздела в МБ
    space_root_used=$(df -BM / | awk 'NR==2 {printf "%.2f MB", $3+0}')

    # SPACE_ROOT_FREE - размер свободного пространства корневого раздела в МБ
    space_root_free=$(df -BM / | awk 'NR==2 {printf "%.2f MB", $4+0}')

    # Экспортируем переменные
    export hostname timezone utc_offset user os date uptime uptime_sec ip mask_dots gateway
    export ram_total ram_used ram_free space_root space_root_used space_root_free
}
# Функция вывода информации о системе на экран
display_system_info() {
    echo "HOSTNAME = $hostname"
    echo "TIMEZONE = $timezone UTC $utc_offset"
    echo "USER = $user"
    echo "OS = $os"
    echo "DATE = $date"
    echo "UPTIME = $uptime"
    echo "UPTIME_SEC = $uptime_sec"
    echo "IP = $ip"
    echo "MASK = $mask_dots"
    echo "GATEWAY = $gateway"
    echo "RAM_TOTAL = $ram_total"
    echo "RAM_USED = $ram_used"
    echo "RAM_FREE = $ram_free"
    echo "SPACE_ROOT = $space_root"
    echo "SPACE_ROOT_USED = $space_root_used"
    echo "SPACE_ROOT_FREE = $space_root_free"
}
