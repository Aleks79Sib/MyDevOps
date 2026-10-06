#!/bin/bash

# Функции для проверки количества аргументов
validate_argument_count () {
    if [ $# -ne 3 ]; then
       echo "Передайте 3 параметра:"
       echo "Использование: $0 <буквы_папок> <буквы_файлов> <размер_файлов>"
       echo "Пример: main.sh az az.az 3Mb"
       exit 1
    fi
}

# Функция проверки английских букв папок
validate_english_chars () {
    local chars="$1"
    local name="$2"
    local exp="$3"
    local re='^([a-z]+)$'
    if ! [[ $chars =~ $re ]]; then
        echo "Некорректные введены символы "$chars""
        echo "Введите строчные буквы английского алфавита в "$name" без цифр, пробелов и других символов."
        echo "Пример: "$exp"" >&2
        exit 1
    fi
}

# Функция проверки длины символов
validate_char_lengths () {
    local chars="$1"
    local max_len="$2"
    local name="$3"
    # Получаем длину строки
    local len=${#chars}
    if [ "$len" -lt 1 ] || [ "$len" -gt "$max_len" ]; then
        echo "Cписок букв английского алфавита, используемых в "$name" "$chars" (не более "$max_len" знаков, указано: $len символов)" >&2
        exit 1
    fi
}

# Функция проверки списка английских букв в имени папок
validate_folder_chars () {
        local chars_folder="$1"
        validate_english_chars "$chars_folder" "названии папок" "az"
        validate_char_lengths "$chars_folder" 7 "названии папок"
}

# Функция проверки букв файлов
validate_file_chars () {
        local chars_file="$1"
        local name="${chars_file%.*}"
        local ext="${chars_file#*.}"

        if [[ "$name" == "$chars_file" ]] || [[ "$ext" == "$chars_file" ]]; then
            echo "Ошибка введенного формата $chars_file "
	    echo "Формат 'имя.расширение' az.az (одна точка)" >&2
            exit 1
        fi

        validate_english_chars "$name" "названии файлов" "az"
        validate_english_chars "$ext" "расширении файлов" "md"
        validate_char_lengths "$name" 7 "названии файлов"
        validate_char_lengths "$ext" 3 "расширении файлов"
}

# Функция проверки формата размера файла
validate_file_size () {
    local file_size="$1"
    #local lower_file_size=$(echo "$file_size" | tr '[:upper:]' '[:lower:]')
    local re='^([0-9]+)Mb$'
    if ! [[ $file_size =~ $re ]]; then
        echo "Некорректный формат размера файла "$file_size". Пример: 3Mb "
        echo "Введите целое число и суффикс  Mb"
        echo "Формат написания размера файла <Цифры><Буквы(Mb)> в Мегабайтах не более 100"
        exit 1
    fi

    # Проверяем, что число от 1 до 100
    local number="${BASH_REMATCH[1]}"
    if [ "$number" -lt 1 ] || [ "$number" -gt 100 ]; then
        echo "Ошибка: размер файла должен быть от 1 до 100 Мегабайтах (указано: $file_size)" >&2
        exit 1
    fi
            
}

