#!/bin/bash

# Подключение файла с функциями получения системной информации
source ../02/system_info.sh 2>/dev/null

# Проверка количества аргументов
if [ $# -ne 4 ]; then
    echo "Используй команду с 4 параметрами: 1-Цвет фона параметров 2-Цвет текста параметров  3-Цвета фона значений 4-Цвет текста значений"
    echo "Параметры в цифрах: $0 <column1_background> <column1_font_color> <column2_background> <column2_font_color>"    
    echo "Используй цвета : 1 - white, 2 - red, 3 - green, 4 - blue, 5 - purple, 6 - black"
    exit 1
fi


# Получение параметров цветов
col1_bg=$1
col1_font=$2
col2_bg=$3
col2_font=$4

# Проверка, что все параметры являются цифрами в диапазоне 1-6
validate_color() {
    local color=$1
    if ! [[ "$color" =~ ^[1-6]$ ]]; then
        echo "Error: Параметры цвета  '$color'должны быть цифрой между 1 и 6"
        exit 1
    fi
}

# Проверка каждого параметра
validate_color "$col1_bg"
validate_color "$col1_font"
validate_color "$col2_bg"
validate_color "$col2_font"

# Проверка на совпадение цветов фона и шрифта в одной колонке
if [ $col1_bg -eq $col1_font ]; then
    echo "Error: Column 1 background and font colors Не должны совпадать!"
    exit 1
fi

if [ $col2_bg -eq $col2_font ]; then
    echo "Error: Column 2 background and font colors Не должны совпадать!"
    exit 1
fi

# Функция для преобразования цветов в ANSI коды
get_color_code() {
    case $1 in
        1) echo 7 ;;  # white
        2) echo 1 ;;  # red
        3) echo 2 ;;  # green
        4) echo 4 ;;  # blue
        5) echo 5 ;;  # purple
        6) echo 0 ;;  # black
        *) echo 9 ;;  # default
    esac
}

# Преобразование цветов в ANSI коды
col1_bg_code=$(get_color_code $col1_bg)
col1_font_code=$(get_color_code $col1_font)
col2_bg_code=$(get_color_code $col2_bg)
col2_font_code=$(get_color_code $col2_font)

# ANSI escape codes
ESC="\033["
RESET="${ESC}0m"

# Функции для цветного вывода
print_colored() {
    local text=$1
    local bg_code=$2
    local font_code=$3
    echo -e "${ESC}4${bg_code};3${font_code}m${text}${RESET}"
}


# Получение системной информации
get_system_info

# Вывод информации с цветами
echo -e "$(print_colored "HOSTNAME" $col1_bg_code $col1_font_code) = $(print_colored "$hostname" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "TIMEZONE" $col1_bg_code $col1_font_code) = $(print_colored "$timezone UTC $utc_offset" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "USER" $col1_bg_code $col1_font_code) = $(print_colored "$user" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "OS" $col1_bg_code $col1_font_code) = $(print_colored "$os" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "DATE" $col1_bg_code $col1_font_code) = $(print_colored "$date" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "UPTIME" $col1_bg_code $col1_font_code) = $(print_colored "$uptime" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "UPTIME_SEC" $col1_bg_code $col1_font_code) = $(print_colored "$uptime_sec" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "IP" $col1_bg_code $col1_font_code) = $(print_colored "$ip" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "MASK" $col1_bg_code $col1_font_code) = $(print_colored "$mask_dots" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "GATEWAY" $col1_bg_code $col1_font_code) = $(print_colored "$gateway" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "RAM_TOTAL" $col1_bg_code $col1_font_code) = $(print_colored "$ram_total" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "RAM_USED" $col1_bg_code $col1_font_code) = $(print_colored "$ram_used" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "RAM_FREE" $col1_bg_code $col1_font_code) = $(print_colored "$ram_free" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "SPACE_ROOT" $col1_bg_code $col1_font_code) = $(print_colored "$space_root" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "SPACE_ROOT_USED" $col1_bg_code $col1_font_code) = $(print_colored "$space_root_used" $col2_bg_code $col2_font_code)"
echo -e "$(print_colored "SPACE_ROOT_FREE" $col1_bg_code $col1_font_code) = $(print_colored "$space_root_free" $col2_bg_code $col2_font_code)"
