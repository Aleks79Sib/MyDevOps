#!/bin/bash

# Чтение системного файла, если он существует
if [ -f "../02/system_info.sh" ]; then
    source ../02/system_info.sh
fi

# Чтение конфигурационного файла, если он существует
if [ -f "./main.conf" ]; then
    source ./main.conf
fi

# Функция проверки цвета
validate_color() {
    local color=$1
    if [[ "$color" =~ ^[1-6]$ ]]; then
        return 0  # корректный цвет
    else
        return 1  # некорректный цвет
    fi
}

# Функция для проверки и установки цвета с fallback на default
get_valid_color() {
    local user_color=$1
    local default_color=$2
    
    if [ -n "$user_color" ] && validate_color "$user_color"; then
        echo "$user_color"
    else
        echo "$default_color"
    fi
}

# Получение валидных параметров цветов
col1_bg=$(get_valid_color "$column1_background" "$default_col1_bg")
col1_font=$(get_valid_color "$column1_font_color" "$default_col1_font")
col2_bg=$(get_valid_color "$column2_background" "$default_col2_bg")
col2_font=$(get_valid_color "$column2_font_color" "$default_col2_font")

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

# Функция для получения названия цвета
get_color_name() {
    case $1 in
        1) echo "white" ;;
        2) echo "red" ;;
        3) echo "green" ;;
        4) echo "blue" ;;
        5) echo "purple" ;;
        6) echo "black" ;;
        *) echo "unknown" ;;
    esac
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

# Вывод информации о цветовой схеме
echo ""
echo -n "Column 1 background = "
if [ -n "$column1_background" ] && validate_color "$column1_background"; then
    echo "$(print_colored "$col1_bg ($(get_color_name $col1_bg))" $col1_bg_code $col1_font_code)"
else
    echo "$(print_colored "default ($(get_color_name $default_col1_bg))" $col1_bg_code $col1_font_code)"
fi

echo -n "Column 1 font color = "
if [ -n "$column1_font_color" ] && validate_color "$column1_font_color"; then
    echo "$(print_colored "$col1_font ($(get_color_name $col1_font))" $col1_bg_code $col1_font_code)"
else
    echo "$(print_colored "default ($(get_color_name $default_col1_font))" $col1_bg_code $col1_font_code)"
fi

echo -n "Column 2 background = "
if [ -n "$column2_background" ] && validate_color "$column2_background"; then
    echo "$(print_colored "$col2_bg ($(get_color_name $col2_bg))" $col2_bg_code $col2_font_code)"
else
    echo "$(print_colored "default ($(get_color_name $default_col2_bg))" $col2_bg_code $col2_font_code)"
fi

echo -n "Column 2 font color = "
if [ -n "$column2_font_color" ] && validate_color "$column2_font_color"; then
    echo "$(print_colored "$col2_font ($(get_color_name $col2_font))" $col2_bg_code $col2_font_code)"
else
    echo "$(print_colored "default ($(get_color_name $default_col2_font))" $col2_bg_code $col2_font_code)"
fi
