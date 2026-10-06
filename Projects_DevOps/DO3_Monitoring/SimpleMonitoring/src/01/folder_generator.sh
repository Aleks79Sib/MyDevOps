#!/bin/bash
source ./name_generator.sh
source ./file_generator.sh
source ./logger.sh

# Функция для проверки свободного места на диске
check_disk_space() {
    # Linux
    local free_space=$(df -k / | tail -n 1 | awk '{print $4}')
    
    local free_gb=$((free_space / 1024 / 1024))
    
    if [ $free_gb -le 1 ]; then
        echo "Недостаточно места на диске (осталось менее 1 ГБ)"
        exit 0
    fi
}

# Функция для генерации названий папок
generate_folder_with_files () {
    # Переменные для папок
    local count_folder="$1"    
    local folder_chars="$2"
    local base_name="$(generate_string "$folder_chars")"
    local target_path="$3"
    local result_name="$base_name"
    local last_char="${base_name: -1}"
    
    # Переменные для файлов
    local count_files="$4"
    local file_chars="$5"
    local size_file="$6"
    local bnf="$(base_name_file "$file_chars")"
    local enf=$(ext_file "$file_chars")
    local first_name_file="$(generate_string "$bnf")"
    local file_size="$(count_kb_file "$size_file")"
    
    # Переменная для логирования
    local log_file="$7"

    for ((i=1; i<=count_folder; i++))
    do
        check_disk_space	    
        result_name+="$last_char"
	folder_name="$(name_add_suffix_date "$result_name")"
	mkdir -p "$target_path/$folder_name"
	dir_path="$target_path/$folder_name"
        log_folder_creation "$log_file" "$dir_path"
	for ((f=1; f<=count_files; f++))
	do
            check_disk_space
	    first_name_file+=$(last_char_name "$bnf")
            file_name="$(generate_single_file "$first_name_file.$enf")"
	    file_path="$dir_path/$file_name"
	    touch "$file_path"
	    $(add_text_to_file "$file_path" "$file_size")
	    local file_size_kbytes=$(ls -lh "$file_path" | awk '{print $5}')
	    # Логируем создание файла
            log_file_creation "$log_file" "$file_path" "$file_size_kbytes"
	done
     done   
}  
