#!/bin/bash

# ==============================================
# Функция вывода инструкций
# ==============================================
show_instructions() {
    echo ""
    echo "==================================================="
    echo "               ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ"
    echo "==================================================="
    echo ""
    echo "Для доступа к сервисам с компьютера пробросим ssh туннель выполните команду:"
    echo "ssh -p 2001 -L 59090:localhost:59090 -L 53000:localhost:53000 -L 59100:localhost:59100 ubuntu@ws1"
    echo ""
    echo "После подключения через SSH откройте в браузере:"
    echo "==================================================="
    echo ""
    echo "1. Grafana:     http://localhost:53000"
    echo "   Логин: admin"
    echo "   Пароль: admin (при первом входе)"
    echo ""
    echo "2. Prometheus:  http://localhost:59090"
    echo ""
    echo "3. Node Exporter: http://localhost:59100"
    echo "==================================================="
    echo ""
    echo "Команды управления:"
    echo "• Остановить контейнеры:  cd /opt/prometheus_stack && sudo docker-compose down"
    echo "• Запустить контейнеры:   cd /opt/prometheus_stack && sudo docker-compose up -d"
    echo "• Просмотр логов:         cd /opt/prometheus_stack && sudo docker-compose logs -f"
    echo "• Перезапустить:          cd /opt/prometheus_stack && sudo docker-compose restart"
    echo ""
    echo "Директории:"
    echo "• Конфиги Prometheus:     /opt/prometheus_stack/prometheus/"
    echo "• Данные Grafana:         /opt/prometheus_stack/grafana/"
    echo "• Docker Compose файл:    /opt/prometheus_stack/docker-compose.yml"
    echo "==================================================="
}
