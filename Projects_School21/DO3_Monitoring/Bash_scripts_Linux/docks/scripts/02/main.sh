source ./system_info.sh 2>/dev/null

# Проверка количества аргументов
if [ $# -ne 0 ]; then
    echo "Ошибка: Скрипт должен быть запущен без параметров"
    exit 1
fi

# Основная логика
get_system_info
display_system_info
echo

# Предложение сохранить данные в файл
read -p "Would you like to save this data to a file? (Y/N): " answer
if [[ $answer == "Y" || $answer == "y" ]]; then
    filename="$(date +%d_%m_%y_%H_%M_%S).status"
    {
        display_system_info
    } > "$filename"
    echo "Data saved to $filename"
else
    echo "Data not saved"
fi
