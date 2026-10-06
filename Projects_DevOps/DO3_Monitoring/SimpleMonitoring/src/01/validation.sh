#!/bin/bash

# Функции для проверки количества аргументов
validate_argument_count () {
    if [ $# -ne 6 ]; then
       echo "Передайте 6 параметров:"
       echo "Использование: $0 <абсолютный путь> <количество_папок> <буквы_папок> <количество_файлов> <буквы_файлов> <размер_файлов>"
       echo "Пример: main.sh /opt/test 4 az 5 az.az 3kb"
       exit 1
    fi
}

# Функция проверки абсолютного пути к директории
validate_absolute_path_to_directiry () {
    local target_path="$1"
    if [[ "$target_path" != /* ]]; then
        echo "Ошибка: "$target_path" Абсолютный путь должен начинаться на /"
	exit 1
    fi
    if [ ! -d "$target_path" ]; then
        echo "Ошибка: Директория '$1' не существует"
	exit 1
    fi
    if [ ! -r "$target_path" ]; then                                                             
        echo "Ошибка: Нет прав на чтение директории '$1'"                    
        exit 1   
    fi
}


# Функция проверки числа
validate_digit () {
    local num="$1"
    local name="$2"
    local re='^[0-9]+$'
    if ! [[ $num =~ $re ]]; then
        echo "Ошибка: "$num" Количество "$name" должно быть целым положительным числом" >&2
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
            echo "Ошибка: формат 'имя.расширение' az.az (одна точка)" >&2
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
    local lower_file_size=$(echo "$file_size" | tr '[:upper:]' '[:lower:]')
    local re='^([0-9]+)kb$'
    if ! [[ $lower_file_size =~ $re ]]; then
        echo "Некорректный формат размера файла "$file_size". Пример: 3kb, 5KB" >&2
        echo "Введите целое число и суффикс k или kb"
	echo "Формат написания размера файла <Цифры><Буквы(kb|KB)> в килобайтах не более 100"
        exit 1
    fi

    # Проверяем, что число от 1 до 100
    local number="${BASH_REMATCH[1]}"
    if [ "$number" -lt 1 ] || [ "$number" -gt 100 ]; then
        echo "Ошибка: размер файла должен быть от 1 до 100 килобайт (указано: $file_size)" >&2
        exit 1
    fi
	    
}


