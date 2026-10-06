#!/bin/bash
source ./name_generator.sh

# Функция для извлечения количества mb 
count_mb_file() {
    local size_file="$1"
    local lower=$(echo "$size_file" | tr '[:upper:]' '[:lower:]')
    if [[ "$lower" =~ ^([0-9]+)mb$ ]]; then
	echo "${BASH_REMATCH[1]}"
    else
        echo "0"  # или exit 1
    fi
}

# Функция создания файла на 1kb
add_text_to_file() {
    local file_path="$1"
    local size_mb="$2"
    # Создаем контент из букв D
    local content=$(head -c 1048576 /dev/zero | LC_ALL=C tr '\0' 'D')
    # Записываем size раз по 1 MБ
    for ((i=1; i<=size_mb; i++)); do
        printf '%s' "$content" >> "$file_path"
    done
}

generate_single_file () {
    local chars="$1"
    local base_name="$(generate_string "$(base_name_file "$chars")")"
    local name_file="$(name_add_suffix_date "$base_name").$(ext_file "$chars")"
    echo "$name_file"
}
