#!/bin/bash

LOG_PATH="/home/lorydari/Projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/04"

get_all_files_log() {
    local log_path="$1"
    local temp_file="temp_file_$(date '+%d%m%y').temp"
    
    # Проверка: существует ли директория
    if [ ! -d "$log_path" ]; then
        echo "Ошибка: директория '$log_path' не существует" >&2
        return 1
    fi

    # Создаём/очищаем временный файл
    > "$temp_file"

    # Находим .log-файлы ТОЛЬКО в указанной директории (без подкаталогов)
    local found=0
    while IFS= read -r -d '' logfile; do
        if [ -f "$logfile" ]; then
            cat "$logfile" >> "$temp_file"
            found=1
        fi
    done < <(find "$log_path" -maxdepth 1 -type f -name "*.log" -print0 2>/dev/null)

    if [ "$found" -eq 0 ]; then
        echo "Предупреждение: в '$log_path' не найдено файлов .log" >&2
    else
        echo "Содержимое .log-файлов сохранено в '$temp_file'" >&2
    fi
    echo "$temp_file"

}

sorted_status_code() {
    local log_file="$1"
    awk '{print $9, $0}' "$log_file" | sort -n | cut -d' ' -f2-

}
get_uniq_ip() {
    local log_file="$1"
    # Первое поле — IP; сортируем и оставляем уникальные
    awk '{print $1}' "$log_file" | sort -u
}

error_status_code() {
    local log_file="$1"
    # Код ответа — 9-е поле; фильтруем 4xx и 5xx
    awk '$9 ~ /^[45][0-9][0-9]$/ {print "Метод запроса: " $6 " " $7 " " $8 " " "Код ошибки: " $9}' "$log_file"
}

uniq_ip_with_error() {
    local log_file="$1"
    # Код ответа — 9-е поле; фильтруем 4xx и 5xx и код ip - 1-ое поле
    awk '$9 ~ /^[45][0-9][0-9]$/ {print "Уникальный IP: " $1 " " "Код ошибки: " $9}' "$log_file" | sort -u
}
# Функция выбора параметра
choice_parametr() {
    choice="$1"
    case $choice in
    1)
        echo "Вы выбрали действие 1"
        echo "Все записи, отсортированные по коду ответа"
	sorted_status_code "$(get_all_files_log "$LOG_PATH")"
	;;
    2)
        echo "Вы выбрали действие 2"
        echo "Все уникальные IP, встречающиеся в записях"
        get_uniq_ip "$(get_all_files_log "$LOG_PATH")"
	;;
    3)
        echo "Вы выбрали действие 3"
        echo "Все запросы с ошибками (код ответа — 4хх или 5хх)"
        error_status_code "$(get_all_files_log "$LOG_PATH")"
	;;
    4)
	echo "Вы выбрали действие 4"
	echo "Все уникальные IP, которые встречаются среди ошибочных запросов"
	uniq_ip_with_error "$(get_all_files_log "$LOG_PATH")"
	;;
    
    *)
        echo "Неверный выбор"
        ;;
esac
}

