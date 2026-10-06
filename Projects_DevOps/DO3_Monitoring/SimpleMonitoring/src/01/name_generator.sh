#!/bin/bash

DATE_SUFFIX=$(date '+%d%m%y')

# Функция для генерации строки
generate_string () {
    local chars="$1"
    
    # Генерируем строку, содержащую каждый символ хотя бы один раз
    local result="$chars"
    local len=${#result}
    
    # Дополняем до минимум 4 символов, добавляя первый символ
    local first_char="${chars:0:1}"  # первый символ
    local prefix="" 
    if [[ "$len" -ge 4 && "$len" -le 7 ]]; then
        result="$chars"
    else 
        while [ "$len" -lt 4 ]; do
            prefix+="$first_char"
            len=$((len + 1))
	    result="${prefix}${chars}"
        done
    fi

    echo "${result}"

}


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

# Функция получения последнего символа
last_char_name () {
    local base_name="$1"
    echo "${base_name: -1}"
}
