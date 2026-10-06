#!/bin/bash

# Генерация 5 файлов логов в точном Combined Log Format (Apache/nginx)
# Спецификация: "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\""

gen_oktet() {
    echo "$(( RANDOM % 256 ))"
}

ip_generation () {
	echo "$(gen_oktet).$(gen_oktet).$(gen_oktet).$(gen_oktet)"
}
value_array() {
    local array="$1"    
    echo ${array[RANDOM % ${#array[@]}]}

}
status_generation() {
    # === Коды ответа (с комментариями) ===
    # 200 — OK: запрос успешно обработан
    # 201 — Created: ресурс успешно создан
    # 400 — Bad Request: ошибка в синтаксисе запроса
    # 401 — Unauthorized: требуется HTTP-аутентификация
    # 403 — Forbidden: доступ запрещён (даже с аутентификацией)
    # 404 — Not Found: запрашиваемый ресурс не существует
    # 500 — Internal Server Error: общая ошибка сервера
    # 501 — Not Implemented: сервер не поддерживает функциональность
    # 502 — Bad Gateway: сервер получил недопустимый ответ от вышестоящего
    # 503 — Service Unavailable: сервер временно не может обработать запрос
    local status_code=(200 201 400 401 403 404 500 501 502 503)
    echo ${status_code[RANDOM % ${#status_code[@]}]}
}

method_generation() {
    local methods=("GET" "POST" "PUT" "PATCH" "DELETE")
    echo "${methods[RANDOM % ${#methods[@]}]}"
}

agent_generation() {
    local agents=("Mozilla" "Google Chrome" "Opera" "Safari" "Internet Explorer" "Microsoft Edge" "Crawler and bot" "Library and net tool")
    echo "${agents[RANDOM % ${#agents[@]}]}"
}

url_generation() {
    local urls=("/index.html" "/login.html" "/admin.html" "/register.html" "/contact.html")
    echo "${urls[RANDOM % ${#urls[@]}]}"
}

# Генерация временных меток в пределах одного дня (отсортированных)
# Генерирует 'count' случайных временных меток (в секундах с эпохи)
# в пределах одного дня, заданного смещением day_offset.
# Возвращает список, отсортированный по возрастанию.
generate_sorted_timestamps() {
    local day_offset="$1"
    local count="$2"
    # Начало дня: 00:00:00 указанной даты
    local base_time
    base_time=$(date -d "$day_offset days ago 00:00:00" +%s) 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "Ошибка: неверная дата" >&2
        return 1
    fi

    local timestamps=()
    for ((i=0; i<count; i++)); do
        # Случайное смещение в течение дня (0–86399 секунд)
        local offset=$(( RANDOM % 86400 ))
        timestamps+=( $((base_time + offset)) )
    done

    # Выводим отсортированный список
    printf '%s\n' "${timestamps[@]}" | sort -n
}

# Преобразует timestamp (в секундах) в формат [DD/Mon/YYYY:HH:MM:SS +0300]
format_log_time() {
    local timestamp="$1"
    date -d "@$timestamp" +"%d/%b/%Y:%H:%M:%S +0300"
}

# Генерирует одну строку Combined Log Format
generate_log_entry() {
    local ip="$1"
    local method="$2"
    local url="$3"
    local status="$4"
    local user_agent="$5"
    local timestamp_sec="$6"

    # Размер ответа: 0–10000 байт; 0 → "-"
    local size=$(( RANDOM % 10001 ))
    [[ "$size" -eq 0 ]] && size="-"

    local time_str
    time_str=$(format_log_time "$timestamp_sec")

    # Формат: IP - - [время] "METHOD URL HTTP/1.1" STATUS SIZE "-" "USER_AGENT"
    printf '%s - - [%s] "%s %s HTTP/1.1" %s %s "-" "%s"\n' \
        "$ip" "$time_str" "$method" "$url" "$status" "$size" "$user_agent"
}

# Генерирует один лог-файл за день, заданный смещением day_offset
generate_log_file() {
    local day_offset="$1"

    # Имя файла: nginx_access_ГГГГММДД.log
    local log_date
    log_date=$(date -d "$day_offset days ago" +"%Y%m%d")
    local log_file="nginx_access_${log_date}.log"

    # Случайное число записей: 100–1000
    local num_entries=$(( RANDOM % 901 + 100 ))

    echo "Генерация $log_file ($num_entries записей)..."

    # Получаем отсортированные временные метки
    mapfile -t timestamps < <(generate_sorted_timestamps "$day_offset" "$num_entries")

    # Очищаем файл
    > "$log_file"

    # Генерируем записи
    for ts in "${timestamps[@]}"; do
        local ip=$(ip_generation)
        local method=$(method_generation)
        local url=$(url_generation)
        local status=$(status_generation)
        local agent=$(agent_generation)

        generate_log_entry "$ip" "$method" "$url" "$status" "$agent" "$ts" >> "$log_file"
    done
}

# Генерирует 5 лог-файлов: за сегодня, вчера, ..., 4 дня назад
log_file_generation() {
    echo "Начинаю генерацию 5 лог-файлов..."
    for day_offset in {0..4}; do
        generate_log_file "$day_offset"
    done
    echo "✅ Готово! Создано 5 лог-файлов."
}
