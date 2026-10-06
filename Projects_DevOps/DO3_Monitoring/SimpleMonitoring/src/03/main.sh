#!/bin/bash

source ./validation.sh
source ./folder_cleanup.sh
# Проверка количества аргументов 
validate_argument_count "$@"

PARAMETER="$1"

validate_digit "$PARAMETER"

choice_parametr "$PARAMETER"

