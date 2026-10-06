#!/bin/bash

source ./validation.sh
source ./folder_generator.sh

FOLDER_CHARS="$1"
FILE_CHARS="$2"
FILE_SIZE="$3"

# Создаем лог-файл
LOG_PATH="/home/lorydari/Projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/02"
LOG_FILE=$(create_log_file "$LOG_PATH")

# Запоминаем время начала
start_time=$(date +%s.%N)
st=$(date)
echo "===================Начало работы скрипта==============="
echo "=== Начало работы скрипта: $st ==="
# === ЛОВУШКА ===
cleanup_and_exit() {
    end_time=$(date +%s.%N)
    et=$(date)
    execution_time=$(echo "$end_time - $start_time" | bc)
    echo "Лог-файл создан: $LOG_FILE"
    #echo "=== Окончание работы скрита: $et ===" >> "$LOG_FILE"
    echo "=== Окончание работы скрипта: $et ==="
    echo "Скрипт отработал: $execution_time секунд"
    echo "Скрипт отработал: $execution_time секунд" >> "$LOG_FILE"
}
trap cleanup_and_exit EXIT
# ================

# Проверка количества аргументов 
validate_argument_count "$@"

# Выполняем проверки
validate_folder_chars "$FOLDER_CHARS"
validate_file_chars "$FILE_CHARS"
validate_file_size "$FILE_SIZE"

# Записываем время начала в лог
log_start_time "$LOG_FILE"

# Генератор папок с файлами
generate_folder_with_files "$FOLDER_CHARS" "$FILE_CHARS" "$FILE_SIZE" "$LOG_FILE"

# Записываем время окончания в лог
log_end_time "$LOG_FILE"
