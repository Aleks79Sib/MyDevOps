#!/bin/bash

DATE_SUFFIX=$(date '+%d%m%y')
# Function add date
name_add_suffix_date () {
    echo "${1}_${DATE_SUFFIX}"
}

# Функция получения базового имени
base_name_file () {
    local chars="$1"
    echo "${chars%.*}"
}
# Функция получения расширения файла
ext_file () {
    local chars="$1"
    echo "${chars#*.}"
}

# Функция получения первого символа
first_char_name () {
    local base_name="$1"
    echo "${base_name:0:1}"
}
# Функция получения последнего символа
last_char_name () {
    local base_name="$1"
    echo "${base_name: -1}"
}

# Функция для генерации строки
generate_string () {
    local chars="$1"
    
    # Генерируем строку, содержащую каждый символ хотя бы один раз
    local result="$chars"
    local len=${#result}
    
    # Дополняем до минимум 5 символов, добавляя первый символ
    local first_char="${chars:0:1}"  # первый символ
    local prefix=""
    # Проверяем слишком длинное имя СРАЗУ
    if [[ "$len" -gt 254 ]]; then
        echo "Имя слишком длинное (не более 255 байт)"
        exit 2
    fi

    # Обрабатываем остальные случаи
    if [[ "$len" -ge 5 && "$len" -le 254 ]]; then
        result="$chars"
    else  # len < 5
        # Добиваем до 5 символов
        while [ "$len" -lt 5 ]; do
            prefix+="$first_char"
            len=$((len + 1))
            result="${prefix}${chars}"
        done
    fi

    echo "${result}"

}
