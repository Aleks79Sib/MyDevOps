#!/bin/bash
source ./name_generator.sh 2>/dev/null

# Функция для извлечения количества kb 
count_kb_file() {
    local size_file="$1"
    local lower=$(echo "$size_file" | tr '[:upper:]' '[:lower:]')
    if [[ "$lower" =~ ^([0-9]+)kb$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "0"  # или exit 1
    fi
}

# Функция создания файла на 1kb
add_text_to_file() {
    local file_path="$1"
    local size_kb="$2"

    # Создаем контент из буквы F
    local content=$(head -c 1024 /dev/zero | tr '\0' 'F')
    # Записываем size_kb раз по 1 КБ
    for ((i=1; i<=size_kb; i++)); do
        printf '%s' "$content" >> "$file_path"
    done
}
generate_single_file () {
    local chars="$1"
    local base_name="$(generate_string "$(base_name_file "$chars")")"
    local result_name="$base_name$(last_char_name "$base_name")"
    name_file="$(name_add_suffix_date "$result_name").$(ext_file "$chars")"
    echo $name_file
}
