#!/bin/bash
source ./goaccess_monitor.sh || { echo "Ошибка при импорте goaccess_monitor.sh"; exit 1; }

main() {
    # Проверка всех парметров       
    generate_goaccess_report "$(get_all_files_log "$LOG_PATH")"
}

main
