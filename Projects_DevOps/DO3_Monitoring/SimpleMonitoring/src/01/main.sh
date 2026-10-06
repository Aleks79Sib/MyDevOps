#!/bin/bash

source ./validation.sh 2>/dev/null
source ./folder_generator.sh 2>/dev/null

# Проверка количества аргументов 
validate_argument_count "$@"

# Извлечение параметров
TARGET_PATH="$1"
# /home/lorydari/Projects/TESTs

NUM_FOLDERS="$2"
FOLDERS="папок"
FOLDER_CHARS="$3"
NUM_FILES="$4"
FILES="файлов в директории"
FILE_CHARS="$5"
FILE_SIZE="$6"
DATE_SUFFIX=$(date '+%d%m%y')

# Выполняем проверки
validate_absolute_path_to_directiry "$TARGET_PATH"
validate_digit "$NUM_FOLDERS" "$FOLDERS"
validate_folder_chars "$FOLDER_CHARS"
validate_digit "$NUM_FILES" "$FILES"
validate_file_chars "$FILE_CHARS"
validate_file_size "$FILE_SIZE"

# Создаем лог-файл
LOG_FILE=$(create_log_file "$TARGET_PATH")

# Записываем время начала в лог
log_start_time "$LOG_FILE"

# Генератор папок с файлами
generate_folder_with_files "$NUM_FOLDERS" "$FOLDER_CHARS" "$TARGET_PATH" "$NUM_FILES" "$FILE_CHARS" "$FILE_SIZE" "$LOG_FILE"

# Записываем время окончания в лог
log_end_time "$LOG_FILE"

echo "Файлы успешно созданы в $TARGET_PATH"
echo "Лог-файл создан: $LOG_FILE"
