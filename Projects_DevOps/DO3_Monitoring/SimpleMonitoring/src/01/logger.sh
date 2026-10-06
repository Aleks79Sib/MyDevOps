#!/bin/bash

# Функция создания лог-файла
create_log_file() {
    local target_path="$1"
    local date=$(date '+%Y_%m_%d_%H_%M_%S')
    local log_file="$target_path/generation_log_$date.log"
    #local log_file="$target_path/log_file.log"
    touch "$log_file"
    echo "$log_file"
}

# Функция записи в лог создания папки
log_folder_creation() {
    local log_file="$1"
    local folder_path="$2"
    local creation_time=$(date '+%d%m%y_%H_%M_%S')
    echo "$creation_time CREATE_DIR $folder_path" >> "$log_file"
}

# Функция записи в лог создания файла
log_file_creation() {
    local log_file="$1"
    local file_path="$2"
    local file_size="$3"
    local creation_time=$(date '+%d%m%y_%H_%M_%S')
    echo "$creation_time CREATE_FILE $file_path SIZE_FILE $file_size_kbytes" >> "$log_file"
}

# Функция записи времени начала в лог
log_start_time() {
    local log_file="$1"
    local start_time=$(date)
    echo "=== Начало генерации: $start_time ===" >> "$log_file"
}

# Функция записи времени окончания в лог
log_end_time() {
    local log_file="$1"
    local end_time=$(date)
    echo "=== Конец генерации: $end_time ===" >> "$log_file"
}
