#!/bin/bash
source ./validation.sh

HEADER='\033[0m'
#HEADER='\033[1;34m'
VALUE='\033[0;32m'
RESET='\033[0m'

LOG_PATH="/home/lorydari/Projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/02/log_file.log"

# Провекра места на диске 
check_disk_space() {
    # Linux
    local free_space=$(df -h / | tail -n 1 | awk '{print $4}')
    echo "Свободного места диске "$free_space""
}

logfile_clean() {
    echo "Функция очистки из лог файла"
    #local log_path="$LOG_PATH"
    check_disk_space
    validation_file "$LOG_PATH"
    while IFS= read -r line; do
        # Проверяем, содержит ли строка "CREATE_DIR"
        if [[ "$line" == *" CREATE_DIR "* ]]; then
            dir_path=$(echo "$line" | awk '{print $3}')
	    echo " DEBAG: директория: "$dir_path""
            delete_dir "$(validation_dir "$dir_path")"
	fi
    done < "$LOG_PATH"
    check_disk_space

}
clean_by_datetime_range() {
    echo "Функия очистки по дате создания"
    local start_input end_input

    read -p "Начало (YYYY-MM-DD HH:MM): " start_input
    read -p "Конец  (YYYY-MM-DD HH:MM): " end_input

    
    validation_date_time "$start_input"
    validation_date_time "$end_input"
    # Используем ассоциативный массив, чтобы не удалять одну папку дважды
    declare -A dirs_to_remove
    echo "Идет поиск подходящих папок 🔎"

    while IFS= read -r -d '' file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            dir=$(dirname "$file")
            # Сохраняем путь, чтобы избежать дубликатов
            dirs_to_remove["$dir"]=1
        fi
    done < <(find / -type f -newermt "$start_input" ! -newermt "$end_input" ! -path "*/bin/*" ! -path "*/sbin/*" ! -path "*/proc/*" ! -path "*/dev/*" ! -path "*/sys/*" ! -path "*/usr/bin/*" ! -name "*.sh" ! -name "*.log" -print0 2>/dev/null)

    # Удаляем уникальные директории
     if [ ${#dirs_to_remove[@]} -eq 0 ]; then
        echo "Нет файлов, соответствующей дате и времени."
        return 0
    fi

    for dir in "${!dirs_to_remove[@]}"; do
        if [ -d "$dir" ]; then
            echo "Найдена папка по файлу: $dir"
            read -p "Удалить со всем содержимым? (y/N): " confirm </dev/tty
            if [[ "$confirm" == [yY] ]]; then
                rm -rf "$dir"
                echo "Удалено: $dir"
            fi
        fi
    done
}

clean_by_name_mask() {
    echo "Функция очистки по имени файла"
    local mask
    read -p "Задай маску (az_31012026 <английские буквы>_<DDMMYYYY>): " mask
    validation_name_mask "$mask"
    # Используем ассоциативный массив, чтобы не удалять одну папку дважды
    declare -A dirs_to_remove
    echo "Идет поиск подходящих папок 🔎"
    while IFS= read -r -d '' file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            basename_file=$(basename "$file")
	    # Проверяем, соответствует ли имя шаблону
	    if [[ "$basename_file" =~ ^[a-z]+_[0-9]{6}(\.[a-z]+)?$ ]]; then
	        dir=$(dirname "$file")
		case "$dir" in
                    /bin/*|/sbin/*|/sys/*|/usr/bin/*) continue ;;
                    *) dirs_to_remove["$dir"]=1 ;;
                esac
	    fi
        fi
    done < <(find / -type f ! -path "*/bin/*" ! -path "*/sbin/*" ! -path "*/sys/*" ! -path "*/usr/bin/*" ! -name "*.sh" ! -name "*.log" -print0 2>/dev/null)

    # Удаляем уникальные директории
    if [ ${#dirs_to_remove[@]} -eq 0 ]; then
        echo "Нет файлов, соответствующих маске."
        return 0
    fi
    for dir in "${!dirs_to_remove[@]}"; do
        if [ -d "$dir" ]; then
            echo "Найдена папка по файлу: $dir"
            read -p "Удалить со всем содержимым? (y/N): " confirm </dev/tty
            if [[ "$confirm" == [yY] ]]; then
                rm -rf "$dir"
                echo "Удалено: $dir"
            fi
        fi
    done
    
}

# Функция выбора параметра
choice_parametr () {
    choice="$1"
    case $choice in
    1)
        echo "Вы выбрали действие 1"
        clean_by_logfile
        ;;
    2)
        echo "Вы выбрали действие 2"
        clean_by_datetime_range
        ;;
    3)
        echo "Вы выбрали действие 3"
        clean_by_name_mask
        ;;
    *)
        echo "Неверный выбор"
        ;;
esac
}

