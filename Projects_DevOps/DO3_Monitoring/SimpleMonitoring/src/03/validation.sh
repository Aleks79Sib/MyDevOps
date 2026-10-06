#!/bin/bash

# Функция для проверки количества аргументов
validate_argument_count () {
    if [ $# -ne 1 ]; then
       echo "Передайте 1 параметр:"
       echo "Использование: $0 параметр со значением 1, 2 или 3"
       echo "1: По лог файлу"
       echo "2: По дате и времени создания"
       echo "3: По маске имени (т. е. символы, нижнее подчёркивание и дата)"
       echo "Пример: main.sh 3"
       exit 1
    fi
}

# Функция проверки числа
validate_digit () {
    local num="$1"
    local re='^[1-3]$'
    if ! [[ $num =~ $re ]]; then
        echo "Ошибка: "$num" должно быть целым положительным числом 1, 2 или 3" >&2
        exit 1
    fi
}

# Функция проверки существования директории
validation_dir() {
    local dir_path="$1"
    if [[ -d "$dir_path" ]]; then
        echo "$dir_path"
    else
        echo "not_found"
   fi   
}   

# Функция проверки существования файла
validation_file() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        echo "$file_path"
    else
        echo "Файл не найден"
        exit 1
    fi
}
# Функция удаления директории

delete_dir() {
    local dir_path="$1"
    if [[ "$dir_path" == "not_found" ]]; then
        echo "Директория не существует"
        return
    fi

    read -p "Удалить найденную директорию '$dir_path'? (Y/N): " answer </dev/tty
    if [[ "$answer" == [Yy] ]]; then
        rm -rf "$dir_path"
        echo "Удалено: $dir_path"
    else
        echo "Удаление отклонено"
    fi
}

# Функция проверки даты
validation_date_time() {
	if [[ ! $1 =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[' '][0-9]{2}:[0-9]{2}$ ]]
	then
		echo "Ошибка в формате даты и времени. Формат: YYYY-MM-DD HH:MM"
		exit 1
	fi	
}

validation_name_mask() {
    local name_mask="$1"
    local re='^[a-z]+_[0-9]{6}(\.[a-z]+)?$'
    if ! [[ $name_mask =~ $re ]]; then
        echo "Некорректно введена маска имени "$name_mask" Пример az_020226 <англискийе буквы>_<DDMMYY>"
        exit 1
    fi
}
