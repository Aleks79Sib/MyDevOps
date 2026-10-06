#!/bin/bash
source ./validation.sh || { echo "Ошибка при импорте validation.sh"; exit 1; }
source ./monitoring.sh || { echo "Ошибка при импорте monitoring.sh"; exit 1; }

PARAMETR="$1"

main() {
    # Проверка всех парметров       
    check_parametrs "$PARAMETR"
    choice_parametr "$PARAMETR"
}

main
