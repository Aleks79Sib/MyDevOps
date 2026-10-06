#!/bin/bash

# Функция создания лог-файла
create_log_file() {
    local target_path="$1"
    local date=$(date '+%H%M%S_%d%m%y')
    #local log_file="$target_path/log_file_$date.log"
    local log_file="$target_path/log_file.log"
    touch "$log_file"
    echo "$log_file"
}

# Функция записи в лог создания папки
log_folder_creation() {
    local log_file="$1"
    local folder_path="$2"
    local creation_time=$(date '+%d%m%y_%H%M%S')
    echo "$creation_time CREATE_DIR $folder_path" >> "$log_file"
}

# Функция записи в лог создания файла
log_file_creation() {
    local log_file="$1"
    local file_path="$2"
    local file_size="$3"
    local creation_time=$(date '+%d%m%y_%H%M%S')
    echo "$creation_time CREATE_FILE $file_path SIZE_FILE $file_size_mbytes" >> "$log_file"
}

# Функция записи времени начала в лог
log_start_time() {
    local log_file="$1"
    local start_time=$(date)
    echo "=== Начало работы скрипта: $start_time ===" >> "$log_file"
}

# Функция записи времени окончания в лог
log_end_time() {
    local log_file="$1"
    local end_time=$(date)
    echo "=== Окончание работы скрипта: $end_time ===" >> "$log_file"
}

