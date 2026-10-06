#!/bin/bash
source ./name_generator.sh
source ./file_generator.sh
source ./create_logger.sh

# Функция для проверки свободного места на диске
check_disk_space() {
    local log_file="$1"
    
    # Получаем свободное место с df -h
    local free_space=$(df -h / | tail -n 1 | awk '{print $4}')
    
    # Извлекаем число и единицу измерения
    local size_num=$(echo "$free_space" | sed 's/[A-Za-z]//g')
    local size_unit=$(echo "$free_space" | sed 's/[0-9.]//g')
    
    # Проверяем в зависимости от единицы измерения
    case "$size_unit" in
        G)
            # Если в гигабайтах - сравниваем с 1.0
            if (( $(echo "$size_num < 1.0" | bc -l) )); then
                echo "Недостаточно места на диске (осталось менее 1 ГБ). Свободно: ${free_space}"
                log_end_time "$log_file"
                exit 0
            fi
            ;;
        M|K|B)
            # Если в мегабайтах, килобайтах или байтах - точно меньше 1 ГБ
            echo "Недостаточно места на диске (осталось менее 1 ГБ). Свободно: ${free_space}"
            log_end_time "$log_file"
            exit 0
            ;;
        T|P)
            # Если в терабайтах или петабайтах - всё ОК, места больше 1 ГБ
            ;;
        *)
            # Неизвестная единица - выводим предупреждение
            echo "Не удалось определить свободное место: ${free_space}"
            ;;
    esac
}
# не создавай файлы в:
#/bin, /sbin, /usr/bin — системные бинарники
#/proc, /sys, /dev — виртуальные ФС ядра

random_dir() {
    find / \
        -type d \
        ! -path "/bin*" \
        ! -path "/sbin*" \
        ! -name "/usr/bin*" \
        ! -path "/sys*" \
        ! -path "/proc*" \
        ! -path "/dev*" \
        -prune 2>/dev/null | shuf -n 1
}

#TARGET_PATH="/home/lorydari/Projects/TESTs/FOLDER"
TARGET_PATH="$random_dir"

# Функция для генерации названий папок
generate_folder_with_files () {
    # Переменные для папок
    local folder_chars="$1"
    local base_name="$(generate_string "$folder_chars")"
    local target_path="$TARGET_PATH"
    
    local result_name="$base_name"
    local last_char="${base_name: -1}"
    local first_char="${base_name:0:1}"
    local count_folder="$(( RANDOM % 100 + 1 ))"    

    # Переменные для файлов
    local file_chars="$2"
    local size_file="$3"
    local bnf="$(base_name_file "$file_chars")"
    local enf=$(ext_file "$file_chars")
    local first_name_file="$(generate_string "$bnf")"
    local file_size="$(count_mb_file "$size_file")"
    
    # Переменная для логирования
    local log_file="$4"
    
    for ((i=1; i<=count_folder; i++))
    do
        check_disk_space "$log_file"	    
        result_name+="$last_char"
	folder_name="$(name_add_suffix_date "$result_name")"
	mkdir -p "$target_path/$folder_name"
	dir_path="$target_path/$folder_name"
        log_folder_creation "$log_file" "$dir_path"
        
	local count_files="$(( RANDOM % 240 + 1 ))"
	local first_name_file="$(generate_string "$bnf")"
	local index=0

	for ((f=1; f<=count_files; f++))
	do
            check_disk_space "$log_file"
	    first_name_file+=$(last_char_name "$bnf")
	    index=$((index + 1))
	    
	    local name_bytes=$(echo -n "$first_name_file" | wc -c)
	    
	    if [[ "$name_bytes" -lt 240 ]]; then
	        : # ничего не делаем	
	    #    first_name_file="$first_name_file"
		#file_name="$(generate_single_file "$first_name_file.$enf")"
            else    
	        local fc="${bnf:0:1}"
		local len=${#first_name_file}
		local result="${first_name_file:0:$((len - index))}"
		local prefix=""
	    	for ((p=0; p<index; p++)); do
                    prefix+="$fc"
                done
		first_name_file="${prefix}${result}"
	    	index=0
            fi
	    file_name="$(generate_single_file "$first_name_file.$enf")" 
	    file_path="$dir_path/$file_name"
            touch "$file_path"
	    add_text_to_file "$file_path" "$file_size"
	    local file_size_mbytes=$(ls -lh "$file_path" | awk '{print $5}')
	    # Логируем создание файла
            log_file_creation "$log_file" "$file_path" "$file_size_mbytes"
	done
     done   
}
