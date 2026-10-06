#!/bin/bash
LOG_PATH="/home/lorydari/Projects/DO4_LinuxMonitoring_v2.0.ID_356280-1/src/04"

get_all_files_log() {
    local log_path="$1"
    local temp_file="temp_file_$(date '+%d%m%y').temp"
    
    # Проверка: существует ли директория
    if [ ! -d "$log_path" ]; then
        echo "Ошибка: директория '$log_path' не существует" >&2
        return 1
    fi

    # Создаём/очищаем временный файл
    > "$temp_file"

    # Находим .log-файлы ТОЛЬКО в указанной директории (без подкаталогов)
    local found=0
    while IFS= read -r -d '' logfile; do
        if [ -f "$logfile" ]; then
            cat "$logfile" >> "$temp_file"
            found=1
        fi
    done < <(find "$log_path" -maxdepth 1 -type f -name "*.log" -print0 2>/dev/null)

    if [ "$found" -eq 0 ]; then
        echo "Предупреждение: в '$log_path' не найдено файлов .log" >&2
    else
        echo "Содержимое .log-файлов сохранено в '$temp_file'" >&2
    fi
    echo "$temp_file"

}

generate_goaccess_report() {
    local log_file="$1"
    local report_file="goaccess_report.html"

    if [ ! -f "$log_file" ]; then
        echo "Ошибка: лог-файл '$log_file' не найден" >&2
        return 1
    fi

    # ===  Генерация отчёта ===
    echo "Генерация отчёта GoAccess: $report_file"
    if goaccess "$log_file" --log-format=COMBINED -o "$report_file" --no-global-config; then
        echo "✅ Отчёт успешно создан: $report_file"
        echo "Чтобы открыть: scp -P 2001 lorydari@127.0.0.1:$(pwd)/$report_file ./ && open ./$report_file"
    else
        echo "❌ Ошибка при генерации отчёта" >&2
        return 1
    fi
}

