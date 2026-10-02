# Simple Docker

## 1. Готовый докер

- Скачивание официального образа nginx
```
docker pull nginx
```

- Проверка наличия образа
```
docker images nginx
```

- Создание и запуск контейнера
```
docker run -d nginx d607865cd608
```


-  Проверка, что контейнер запущен
```
docker ps
```
![docker ps](./part_1/images/image_1.png)

-  Информация о контейнере (docker inspect)
```
docker inspect 5706cae7e821
docker inspect --size 5706cae7e821 | grep -E '"SizeRootFs"|"SizeRw"'
```
- **Размер контейнера (SizeRootFs):** 180,953,022 байт (~185 MB)

- **Слой записи (SizeRw):** 1095 байт

- **Замапленные порты:** 80/tcp (на момент первого 
запуска без `-p` порты не замаплены)

- **IP контейнера:** 172.17.0.2

![docker inspect](./part_1/images/docker_inspect_size_ip.png)

![docker inspect](./part_1/images/docker_inspect_1.png)

![docker inspect](./part_1/images/docker_inspect_2.png)

![docker inspect](./part_1/images/docker_inspect_3.png)

![docker inspect](./part_1/images/docker_inspect_4.png)

- Остановка контейнера
```
docker stop 5706cae7e821
```

-  Проверка, что контейнер остановлен
```
docker ps
```

![docker ps after stop](./part_1/images/docker_stop.png)

- Запуск контейнера с пробросом портов 80 и 443
```
docker run -d -p 80:80 -p 443:443 nginx
```
![docker run with ports](./part_1/images/docker_run_ports_80_443.png)

- Проверка доступности nginx по адресу localhost:80
```
curl -s http://127.0.0.1:80
```
![nginx welcome page](./part_1/images/screen_localhost.png)


Стартовая страница **nginx** доступна по адресу `127.0.0.1:80` (заголовок: "Welcome to nginx!").

![nginx welcome page](./part_1/images/docker_browser_nginx.png)

- Перезапуск контейнера
```
docker restart
# Заново запускал контейнер  поэтому id контейнера изменился на 649430a9d8b3
docker ps
```
![docker restart](./part_1/images/docker_restart.png)

Контейнер успешно перезапущен: статус `Up`.

## 2. Операции с контейнером

- Прочитал конфигурационный файл nginx.conf внутри докер контейнера через команду exec.

```
docker exec 649430a9d8b3 cat /etc/nginx/nginx.conf

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}

```
![docker exec cat nginx.conf](./part_2/images/docker_exec_cat_nginx_conf.png)

- Создал на локальной машине файл nginx.conf.

Создан файл `nginx.conf` с содержимым:
```
server {
    listen 80;
    server_name localhost;

    location /status {
        stub_status on;
        allow all;
        access_log off;
    }
}
```
![nginx.conf](./part_2/images/vim_nginx_conf.png)

- Настроил в нем по пути /status отдачу страницы статуса сервера nginx.

Файл настроен. Server-блок со `stub_status` добавлен в `/etc/nginx/nginx.conf` внутрь директивы `http {}`.

- Скопировал созданный файл nginx.conf внутрь докер-контейнера через команду docker cp.

```
docker cp nginx.conf 2ec4f4984f5e:/etc/nginx/nginx.conf
```

- Перезапустил nginx внутри докер-контейнера через команду exec.

```
docker exec 2ec4f4984f5e nginx -s reload
```

- Проверил, что по адресу localhost:80/status отдается страничка со статусом сервера nginx.

```
curl http://127.0.0.1:80/status

Active connections: 1
server accepts handled requests
 7 7 4
Reading: 0 Writing: 1 Waiting: 0
```

![docker cp _ reload](./part_2/images/docker_cp_nginx_conf_reload.png)

![curl /status](./part_2/images/localhost_status.png)


- Экспортировал контейнер в файл container.tar через команду export.

```
docker export 2ec4f4984f5e -o container.tar
```
![docker export](./part_2/images/container_tar.png)

- Остановил контейнер.

```
docker stop 2ec4f4984f5e
```

- Удалил образ через docker rmi [image_id|repository], не удаляя перед этим контейнеры.

```
docker rmi -f nginx
```

- Удалил остановленный контейнер.

```
docker rm 2ec4f4984f5e
```
![Удаление и Остановка контейнера](./part_2/images/rmi_rm_docker.png)

- Создал образ из файла container.tar через команду import.

```
docker import container.tar nginx:latest
```

![docker import](./part_2/images/import_container.png)

- Создал и запустил контейнер на основе импортированного образа.

```
docker run -d -p 80:80 -p 443:443 nginx-new nginx -g "daemon off;"
docker ps
```
![docker run](./part_2/images/docker_run_nginx_new.png)

- Проверил, что по адресу localhost:80/status отдается страничка со статусом сервера nginx.

```
curl http://127.0.0.1:80/status
```
![curl /status ](./part_2/images/curl_new_status.png)

![status after import](./part_2/images/new_status_nginx.png)

## 3. Мини веб-сервер

- Написал мини-сервер на C и FastCgi, возвращающий "Hello, World!"

Файл `src/server/hello.c`:
```c
#include <fcgiapp.h>

int main() {
    FCGX_Request req;
    FCGX_Init();
    FCGX_InitRequest(&req, 0, 0);

    while (FCGX_Accept_r(&req) >= 0) {
        FCGX_FPrintF(req.out, "Content-Type: text/html\n\n");
        FCGX_FPrintF(req.out, "<html><body><h1>Hello, World!</h1></body></html>");
        FCGX_Finish_r(&req);
    }

    return 0;
}
```
[файл hello.c](./server/hello.c)

Компиляция:
```
cd server
gcc -o hello hello.c -I/opt/homebrew/include -L/opt/homebrew/lib -lfcgi
```

- Запустил мини-сервер через spawn-fcgi на порту 8080

```
spawn-fcgi -p 8080 ./hello

ps aux | grep hello | grep -v grep && lsof -i :8080 | grep LISTEN
```
![spawn-fcgi](./part_3/images/spawn-fcgi.png)

- Написал nginx.conf, проксирующий запросы с 81 порта на 127.0.0.1:8080

Файл [nginx.conf](./server/nginx.conf):
```nginx
events {
    worker_connections 1024;
}

http {
    server {
        listen 81;
        server_name localhost;

        location / {
            fastcgi_pass host.docker.internal:8080;
            include fastcgi_params;
        }
    }
}
```



- Запустил nginx в Docker с написанной конфигурацией

```
docker run -d -p 81:81 --name nginx-part3 nginx
docker cp nginx.conf [container_id]:/etc/nginx/nginx.conf
docker exec [container_id] nginx -s reload

curl http://127.0.0.1:81
<html><body><h1>Hello, World!</h1></body></html>
```
![nginx](./part_3/images/restart_Nginx.png)

- Проверил, что по localhost:81 отдается страничка "Hello, World!"

![localhost:81](./part_3/images/loccalhost_81.png)

- Положил nginx.conf по пути ./nginx/nginx.conf

```
cd src
mkdir -p nginx
cp sever/nginx.conf nginx/nginx.conf
```


## 4. Свой докер

- Создал докерфайл  Dockerfile.part4

[Dockerfile.part4](Dockerfile.part4)

- Создал докер-образ через docker build при этом указав имя hello-fcgi и тег part_4
```
# Перейти в src
cd src

# Запускать из src
docker build -f Dockerfile.part4 -t hello-fcgi:part_4 .
```
![docker build](./part_4/images/dockerfile_build.png)

- Проверили через docker images hello-fcgi:part_4

```
docker images hello-fcgi:part_4
```

![docker images](./part_4/images/docker_images.png)

- Запустили контейнер докер-образ с маппингом 81 порта на 80 на локальной машине и маппингом папки ./nginx внутрь контейнера

```
docker run -d -p 80:81 -v $(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf hello-fcgi:part_4
```

![docker run](./part_4/images/docker_run.png)

- Проверили что сайт доступен по адресу http://localhost:80

![localhost](./part_4/images/localhost.png)]

![browser](./part_4/images/browser.png)]

- Допишим в ./nginx/nginx.conf проксирование странички /status, по которой надо отдавать статус сервера nginx.

```
location /status {                                                                                           
    stub_status on;
    allow all;
    access_log off;                                                                                           
}
```

[nginx.conf](./nginx/nginx.conf)

- Перезапустим docker

```
docker restart 7b39e650378f
```

![docker restart](./part_4/images/docker_restart.png)

- Проверим, что теперь по localhost:80/status отдается страничка со статусом nginx

![localhost:80/status](./part_4/images/localhost_status.png)

![browser](./part_4/images/browser_status.png)]


## 5. Dockle

- Установим Dockle

- запустим dockle и проверим образ

```
dockle hello-fcgi:part_4
```

![dockle](./part_5/images/dockle_scan.png)

- Выявили следующие ошибки и предупреждения:

```
FATAL	- CIS-DI-0010: Не храните учетные данные в переменных/файлах среды.
WARN	- CIS-DI-0001: Создайте пользователя для контейнера
	* Последний пользователь не должен быть root
INFO	- CIS-DI-0005: Включить доверие к содержимому для Docker
	* export DOCKER_CONTENT_TRUST=1 перед извлечением/сборкой докера
INFO	- CIS-DI-0006: Добавьте инструкцию HEALTHCHECK в образ контейнера.
	* не найден оператор HEALTHCHECK
INFO	- CIS-DI-0008: Подтвердите безопасность файлов setuid/setgid.
```

- Исправили ошибки в Dockerfile.part5

[Dockerfile.part5](Dockerfile.part5)

- Забилдили новый образ

```
docker build -f Dockerfile.part5 -t hello-fcgi:part_5 .
docker images hello-fcgi:part_5
```

![docker_part5](./part_5/images/docker_build.png)

- Запустили скан на уязвимости 

```
dockle hello-fcgi:part_5
INFO	- CIS-DI-0008: Confirm safety of setuid/setgid files
# Можем проигнорировать
```

![dockle_scan](./part_5/images/dockle_scan_2.png)

- Запустили контейнер и проверили, что все работает

```
sudo docker run -d -p 80:81 -v $(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf hello-fcgi:part_5
```

![docker_ps](./part_5/images/docker_ps.png)

![localhost](./part_5/images/localhost.png)]

## 6. Базовый Docker Compose

- Собрали docker-compose файл, который содержит:
  - докер-контейнер из Части 5 (он должен работать в локальной сети, т. е. не нужно использовать инструкцию EXPOSE и мапить порты на локальную машину).

  - докер-контейнер с nginx, который будет проксировать все запросы с 8080 порта на 81 порт первого контейнера.

  - Замапили 8080 порт второго контейнера на 80 порт локальной машины.

[docker-compose.yml](docker-compose.yml)


- Остановили все запущенные контейнеры.

```
docker stop $(docker ps -a -q)
```

- Запустили проект с помощью команд docker compose build и docker compose up.

```
docker ps
docker compose build
docker compose up
docker ps
```
![docker-compose-up](./part_6/images/docker_compose_build_up_d.png)


- Проверили, что в браузере по localhost:80 отдается написанная страничка, как и ранее

![http://localhost:80](./part_6/images/browser_localhost.png)

![status](./part_6/images/status.png)
