#!/bin/bash

install_nginx() {

    echo "Установка nginx"
    sudo apt-get update
    sudo apt-get install nginx -y

    echo "Проверка установки версии nginx"
    nginx -v
	
}

configure_nginx() {
    local config_path="/etc/nginx/sites-available/custom-metrics"
    sudo tee "$config_path" > /dev/null << 'EOF'
server {
    listen 9200;
    server_name localhost;

    location / {
        root /var/www/html/metrics;
        index index.html;
        types { }
        default_type "text/plain; version=0.0.4; charset=utf-8";
    }
}
EOF
    echo "Конфигурация Nginx сохранена в $config_path"
}

active_nginx() {
    echo "Создать симлинк"
    sudo ln -s /etc/nginx/sites-available/custom-metrics /etc/nginx/sites-enabled/

    echo "Проверить конфигурацию"
    sudo nginx -t

    echo "Перезапустить nginx"
    sudo systemctl restart nginx
    
    echo "Проверить статус"
    sudo systemctl status nginx
}

install_nginx
configure_nginx
active_nginx



