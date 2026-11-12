# Отчет по проекту "Инструменты автоматизации"

## Part 1. Удаленное конфигурирование узла через Ansible

### 1. Создание виртуальных машин через Vagrant

**Vagrantfile** создан с тремя машинами: `manager`, `node01`, `node02`. Docker через shell-скрипты не устанавливался. Проброшены порты с `node01` на локальную машину для доступа к микросервисному приложению.

Содержимое [Vagrantfile](./ansible01/Vagrantfile)

![vagrant up](../docs/screenshots/part1/vagrant_up.png)

![vagrant status](../docs/screenshots/part1/vagrant_status.png)

---

### 2. Подготовка manager как рабочей станции Ansible

#### 2.1. Подключение к manager и проверка SSH до node01

```bash
vagrant ssh manager
ssh vagrant@192.168.121.121
```

#### 2.2. Генерация SSH-ключа

```bash
ssh-keygen -C "комментарий"
ssh-copy-id vagrant@192.168.121.122
ssh-copy-id vagrant@192.168.121.123
```

![vagrant ssh manager](../docs/screenshots/part1/ssh-copy-node01.png)

- Первый вход на node01

![node01](../docs/screenshots/part1/entre_first_node01.png)

- Вход по ssh на node01

![node01](../docs/screenshots/part1/entre_ssh_node01.png)

#### 2.3. Копирование docker-compose файла и исходного кода микросервисов

```bash
scp -r /home/vagrant/src/node01/* vagrant@192.168.121.122:~/app/
```
#### 2.4. Установка Ansible и создание inventory-файла

- на manager:

```bash
sudo apt update
sudo apt install ansible -y
mkdir ~/ansible
```
/home/vagrant/src/ansible
Содержимое [inventory-файла](./ansible01/inventory.ini)

- Проверяем конфиг

![inventory.ini](../docs/screenshots/part1/inventory.png)

#### 2.5. Проверка подключения модулем ping

```bash
ansible all --key-file ~/.ssh/id_rsa -i ~/ansible/inventory -m ping
```

**Результат выполнения модуля ping:**

```
192.168.121.122 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
192.168.121.123 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

![ping](../docs/screenshots/part1/ping_node01.png)

![ping](../docs/screenshots/part1/ping_node02.png)

---

### 3. Написание первого плейбука Ansible

Плейбук выполняет:
- `apt update`
- установка docker
- установка docker-compose
- копирование compose-файла из manager на node01
- развертывание микросервисного приложения

Содержимое [ansible_playbook](./ansible01/playbook.v1.yaml)

**Скриншот выполнения плейбука `ansible-playbook`:**

![ansible-playbook-1](../docs/screenshots/part1/ansible_playbook1.png)

![ansible-playbook-2](../docs/screenshots/part1/ansible_playbook2.png)

**Скриншот проверки запущенных контейнеров на node01:**

![docker ps](../docs/screenshots/part1/docker_ps.png)

---

### 4. Тестирование через Postman

Запущены тесты из файла `application_tests.postman_collection.json`.

**Результаты тестирования:**

**Скриншот Postman с результатами прохождения тестов:** 

![postman](../docs/screenshots/part1/postman_test_all.png)


---

### 5. Создание ролей Ansible

#### 5.1. Роль `application`

Структура роли:

```
roles/
  application/
    tasks/
      main.yml
```

Роль `application` разворачивает микросервисное приложение через docker-compose (назначается на node01).

 [roles/application/tasks/main.yml](./ansible01/roles/application/tasks/main.yaml)

#### 5.2. Роль `apache`

```
roles/
  apache/
    tasks/
      main.yml
```

Роль `apache` устанавливает и запускает Apache сервер (назначается на node02).

[roles/apache/tasks/main.yml](./ansible01/roles/apache/tasks/main.yaml)

#### 5.3. Роль `postgres`

```
roles/
  postgres/
    tasks/
      main.yml
```

Роль `postgres` устанавливает и запускает PostgreSQL, создает базу данных с произвольной таблицей и добавляет три произвольные записи (назначается на node02).

[roles/postgres/tasks/main.yml](./ansible01/roles/postgres/tasks/main.yaml)

#### 5.4. Назначение ролей

- `application` -> node01
- `apache` + `postgres` -> node02

[playbook с ролями](./ansible01/playbook.yaml)

- Запуск ansible-playbook с ролями

![1](../docs/screenshots/part1/ansible_roles_1.png)
![2](../docs/screenshots/part1/ansible_roles_2.png)
![3](../docs/screenshots/part1/ansible_roles_3.png)
![4](../docs/screenshots/part1/ansible_roles_4.png)

#### 5.5. Проверка работоспособности

**Микросервисное приложение (node01):** Postman-тесты пройдены успешно.

**Скриншот:Postman-тестов**

![postman](../docs/screenshots/part1/postman_test_2.png)


**Apache сервер (node02):** веб-страница открывается в браузере.

![apache2](../docs/screenshots/part1/apache_browser.png)

**PostgreSQL (node02):** подключение с локальной машины и отображение содержимого таблицы.

```bash
psql -h 192.168.121.123 -U postgres -d <db_name> -c "SELECT * FROM <table_name>;"
```

![postgres](../docs/screenshots/part1/postgres_node02.png)

---

### 6. Размещение файлов Part 1

Все файлы части 1 размещены в папке `src/ansible01/`.

```
src/ansible01/
  Vagrantfile
  playbook.yml
  inventory
  roles/
    application/
      tasks/
        main.yml
    apache/
      tasks/
        main.yml
    postgres/
      tasks/
        main.yml
```

---

## Part 2. Service Discovery

### 1. Конфигурационные файлы Consul

#### consul_server.hcl

- Создали конфиг 

[consul_server.hcl](./consul01/consul_server.hcl)

#### consul_client.hcl

- Создали конфиг 

[consul_client.hcl](./consul01/consul_client.hcl)

---

### 2. Создание виртуальных машин через Vagrant

Созданы 4 машины:
- `consul_server` -- порт 8500 проброшен для доступа к UI Consul
- `api` -- порт 8082 проброшен для доступа к API
- `manager` -- рабочая станция Ansible
- `db` -- сервер базы данных

![vagrant](../docs/screenshots/part2/vagrant_up_4.png)
![vagrant](../docs/screenshots/part2/vagrant_up_4_finished.png)

**Скриншот: vagrant status всех 4 машин**

![vagrant](../docs/screenshots/part2/vagrant_status_4m.png)

Зашли на manager:
- Сделали генерацию ssh-keygen
![ssh](../docs/screenshots/part2/ssh_manager_keygen.png)

- Скопировали ключ ssh на остальные машины
![ssh](../docs/screenshots/part2/ssh-copy-id-machines.png)

- Проверили вход на машины
![ssh](../docs/screenshots/part2/entre_ssh_vm.png)

---

### 3. Плейбук Ansible и 4 роли

на manager:
 - сделали установку ansible
 ```bash
 sudo apt update && sudo apt install ansible -y
 ```
 - создали директрии src , ansible , consul
 - скопировали (создали ) файлы ansible и consul01 , services/hotel-service
 - проверили содержимое src - `ls -la`
![manager](../docs/screenshots/part2/manager_src.png)

 - Проверили пинг до машин `ansible-inventory -i inventory.ini --list` и `ansible all -m ping -i inventory.ini`

![ansible list](../docs/screenshots/part2/ansible_inventory_list.png)

![ansible ping](../docs/screenshots/part2/ansible_inventory_ping.png)

 - файл [playbook.yaml](./ansible02/playbook.yaml)


#### 3.1. Роль `install_consul_server`

Назначена на `consul_server`. Выполняет:
- копирование `consul_server.hcl`
- установка consul и зависимостей

Мы собрали бинарник Consul из исходников на самом homeserver (не внутри VM):                     
                                                                                                  
 ```bash                                                                                          
   # На homeserver                                                                                
   sudo apt install -y golang-go git                                                              
                                                                                                  
   git clone https://github.com/hashicorp/consul.git                                              
   cd consul                                                                                      
   git checkout v2.0.2                                                                            
   go build -o consul .                                                                           
                                                                                                  
   # Скопировали в папку проекта                                                                  
   cp consul /workspace/projects/DO8_AutomationTools_ID_1220167-1/src/ansible02/consul            
 ```                                                                                              
                                                                                                  
 Потом этот бинарник через copy в роли install_consul_server и install_consul_client копировался  
 с manager на target-машины:                                                                      
                                                                                                  
 ```yaml                                                                                          
   - name: "Копировать Consul бинарник"                                                           
     copy:                                                                                        
       src: /home/vagrant/src/consul01/consul                                                     
       dest: /usr/local/bin/consul                                                                
       mode: 0755                                                                                 
 ```                                                                                              



- запуск сервиса consul


#### 3.2. Роль `install_consul_client`

Назначена на `api` и `db`. Выполняет:
- копирование `consul_client.hcl`
- установка consul, envoy и зависимостей
- запуск сервисов consul и consul-envoy

#### 3.3. Роль `install_db`

Назначена на `db`. Выполняет:
- установка и запуск PostgreSQL
- создание базы данных `hotels_db`

#### 3.4. Роль `install_hotels_service`

Назначена на `api`. Выполняет:
- копирование исходного кода сервиса (hotel-service)
- установка `openjdk-21-jdk`
- создание глобальных переменных окружения:
  - `POSTGRES_HOST="127.0.0.1"`
  - `POSTGRES_PORT="5432"`
  - `POSTGRES_DB="hotels_db"`
  - `POSTGRES_USER="postgres"`
  - `POSTGRES_PASSWORD="postgres"`
- запуск jar-файла

**Скриншот: выполнения плейбука `ansible-playbook`**

![ansible1](../docs/screenshots/part2/ansible-playbook-1.png)

![ansible2](../docs/screenshots/part2/ansible-playbook-2.png)

---

### 4. Проверка CRUD-операций сервиса отелей

**CRUD-операции:**
- **Create (POST):** `/api/v1/hotels`
- **Read (GET):** `/api/v1/hotels` и `/api/v1/hotels/{id}`
- **Update (PUT):** `/api/v1/hotels/{id}`
- **Delete (DELETE):** `/api/v1/hotels/{id}`

- Копируем токен 
```bash
B64=$(echo -n "b51ceda2-bfa5-11eb-8529-0242ac130003" | base64)
TOKEN=$(curl -s -i "http://localhost:8082/api/v1/hotels/authorize" -H "authorization: Basic $B64" | grep -i "^authorization:" | sed 's/authorization: //I' | tr -d '\r')
echo "TOKEN=$TOKEN"
```

- 1 тест GET:

```bash
curl -i http://localhost:8082/api/v1/hotels -H "authorization: $TOKEN"
```

![read](../docs/screenshots/part2/READ_hotel.png)

- 2 тест Create:

```bash
curl -i -X POST http://localhost:8082/api/v1/hotels \
  -H "authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Hotel",
    "location": {
      "country": "Country 1",
      "city": "City 1",
      "address": "New Test Address"
     }
  }'
```

![Create](../docs/screenshots/part2/CREATE_hotel.png)

- 3 тест READ:

```bash
curl -s http://localhost:8082/api/v1/hotels -H "authorization: $TOKEN" | python3 -m json.tool
```

![read](../docs/screenshots/part2/READ_AFTER_CREATE_hotel.png)

- 4 тест READ:

```bash
curl -i http://localhost:8082/api/v1/hotels/bba48b43-5e8d-45cc-8ada-b6090b4bf67a -H "authorization: $TOKEN"
```

![read3](../docs/screenshots/part2/READ_new_hotel.png)

- 5 тест UPDATE:

```bash
 curl -i -X PATCH http://localhost:8082/api/v1/hotels/bba48b43-5e8d-45cc-8ada-b6090b4bf67a/rooms \
  -H "authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

![Update](../docs/screenshots/part2/UPDATE_method_not_allowed.png)

- 6 TEST DELETE:

```bash
curl -i -X DELETE http://localhost:8082/api/v1/hotels/bba48b43-5e8d-45cc-8ada-b6090b4bf67a -H "authorization: $TOKEN"
```

![DELETE](../docs/screenshots/part2/DELETE_method_not_allowed.png)

**‼️Результаты тестирования‼️:
Полного CRUD в этом сервисе физически не существует — Update и Delete не реализованы разработчиком (Update даже закомментирован прямо в контроллере)** 
[👉Смотреть здесь](./services/hotel-service/src/main/java/com/s21/devops/sample/hotelservice/Controller/HotelsController.java)


**Скриншот: UI Consul (порт 8500) с зарегистрированными сервисами**

![consul nodes](../docs/screenshots/part2/consul_nodes.png)

![consul services](../docs/screenshots/part2/consul_services.png)

---

### 5. Размещение файлов Part 2

- Файлы ролей и плейбук Ansible размещены в `src/ansible02/`
- Файлы конфигурации Consul размещены в `src/consul01/`

```
src/consul01/
  consul_server.hcl
  consul_client.hcl

src/ansible02/
  playbook.yml
  inventory
  roles/
    install_consul_server/
      tasks/
        main.yml
    install_consul_client/
      tasks/
        main.yml
    install_db/
      tasks/
        main.yml
    install_hotels_service/
      tasks/
        main.yml
```

---

## Заключение

В ходе выполнения проекта были изучены и применены:

1. **Vagrant** -- создание и управление виртуальными машинами
2. **SSH** -- настройка удаленного подключения по ключам
3. **Ansible** -- автоматизация удаленного конфигурирования узлов (плейбуки, роли, inventory)
4. **Consul** -- Service Discovery с клиент-серверной архитектурой
