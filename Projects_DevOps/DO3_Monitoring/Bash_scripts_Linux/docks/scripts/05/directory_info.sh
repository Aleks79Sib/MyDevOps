#!/bin/bash

HEADER='\033[0m'
#HEADER='\033[1;34m'
VALUE='\033[0;32m'
#VALUE='\033[0m'
RESET='\033[0m'

get_directory_info() {
    local DIR="$1"
    local counter=1
    
    # 1. Всего папок
    local folders=$(find "$DIR" -type d 2>/dev/null | wc -l)
    echo -e "${HEADER}Total number of folders (including all nested ones) = ${VALUE}$((folders - 1))${RESET}"
    
    # 2. Топ-5 папок
    echo -e "${HEADER}TOP 5 folders of maximum size arranged in descending order (path and size):${RESET}"
    counter=1
    du -sh "$DIR"*/ 2>/dev/null | sort -hr | head -5 | while read size path; do
        echo -e "${VALUE}$counter - $path, $size${RESET}"
        ((counter++))
    done
    
    # 3. Всего файлов
    echo -e "${HEADER}Total number of files = ${VALUE}$(find "$DIR" -type f 2>/dev/null | wc -l)${RESET}"
    
    # 4. Статистика
    echo -e "${HEADER}Number of:${RESET}"
    echo -e "${HEADER}Configuration files (with the .conf extension) = ${VALUE}$(find "$DIR" -name "*.conf" -type f 2>/dev/null | wc -l)${RESET}"
    echo -e "${HEADER}Text files = ${VALUE}$(find "$DIR" \( -name "*.txt" -o -name "*.md" -o -name "*.doc" -o -name "*.docx" -o -name "*.pdf" \) -type f 2>/dev/null | wc -l)${RESET}"
    echo -e "${HEADER}Executable files = ${VALUE}$(find "$DIR" -type f -executable 2>/dev/null | wc -l)${RESET}"
    echo -e "${HEADER}Log files (with the extension .log) = ${VALUE}$(find "$DIR" -name "*.log" -type f 2>/dev/null | wc -l)${RESET}"
    echo -e "${HEADER}Archive files = ${VALUE}$(find "$DIR" \( -name "*.zip" -o -name "*.tar" -o -name "*.gz" -o -name "*.bz2" -o -name "*.7z" -o -name "*.rar" \) -type f 2>/dev/null | wc -l)${RESET}"
    echo -e "${HEADER}Symbolic links = ${VALUE}$(find "$DIR" -type l 2>/dev/null | wc -l)${RESET}"
    
    # 5. Топ-10 файлов (ПРОСТО РАСШИРЕНИЕ)
    echo -e "${HEADER}TOP 10 files of maximum size arranged in descending order (path, size and type):${RESET}"
    counter=1
    find "$DIR" -type f -exec du -sh {} \; 2>/dev/null | sort -hr | head -10 | while read size path; do
        # Просто получаем расширение
        filename=$(basename "$path")
        extension="${filename##*.}"
        
        # Если нет расширения
        if [ "$filename" = "$extension" ]; then
            extension="no_ext"
        fi
        
        echo -e "${VALUE}$counter - $path, $size, $extension${RESET}"
        ((counter++))
    done
    
    # 6. Топ-10 исполняемых с MD5
    echo -e "${HEADER}TOP 10 executable files of the maximum size arranged in descending order (path, size and MD5 hash of file):${RESET}"
    counter=1
    find "$DIR" -type f -executable -exec du -sh {} \; 2>/dev/null | sort -hr | head -10 | while read size path; do
        hash=$(md5sum "$path" 2>/dev/null | cut -d' ' -f1)
        if [ -z "$hash" ]; then
            hash="no_hash"
        fi
        echo -e "${VALUE}$counter - $path, $size, $hash${RESET}"
        ((counter++))
    done
}
