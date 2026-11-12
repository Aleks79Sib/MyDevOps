# Отчёт по проекту «Basic Kubernetes»

**Автор: _username_**

**Дата выполнения: _11.08.2026_**

---

## Оглавление

1. [Часть 1. Использование готового манифеста](#часть-1-использование-готового-манифеста)
2. [Часть 2. Написание собственного манифеста](#часть-2-написание-собственного-манифеста)

---

## Часть 1. Использование готового манифеста

### 1 Установка Установка инструментов

Прежде чем запускать кластер, убедитесь, что у вас установлены:

kubectl – CLI для управления Kubernetes.

Minikube – инструмент для локального запуска Kubernetes.

Гипервизор или контейнерный движок – например, Docker, VirtualBox, Hyper-V и т.д.
(рекомендуем Docker, он наиболее прост в настройке).

- **1.1. Kubectl**

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

- **1.2 Minikube**

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

- **1.3 Docker (если не установлен)**

```bash
sudo apt update && sudo apt install docker.io
sudo systemctl start docker
sudo usermod -aG docker $USER   # перезайдите в систему после этого
```

![install_kuber](./screenshots/part1/install_kuber_minikube.png)

- **1.4. Запуск окружения Kubernetes (4 GB памяти)**

```bash
minikube start --memory=4096
```

![minikube start](./screenshots/part1/minikube_starting.png)

**Проверка статуса кластера:**
```bash
minikube status
kubectl cluster-info
kubectl get nodes
```

![status](./screenshots/part1/minicube_status.png)

---

### 2. Применение манифеста из `/src`


```bash
kubectl apply -f example/microservices.yml
```

![apply](./screenshots/part1/apply_manifest.png)

**Проверка применённых объектов:**
```bash
kubectl get all
```

![get_all](./screenshots/part1/kubectl_get_all.png)

---

### 3. Запуск стандартного дашборда Kubernetes

```bash
minikube dashboard
```

![minicube_dashboard](./screenshots/part1/minicube_dashboard.png)

Получили ссылку и открыли по ней дашборд

![dashboard1](./screenshots/part1/dashboards_deployments.png)
![dashboard2](./screenshots/part1/dashboard_pods.png)
![dashboard3](./screenshots/part1/dashboards_services.png)

---

### 4. Проброс туннеля к сервису apache

```bash
minikube service apache --url
minikube service catalog --url
minikube service customer --url
minikube service order --url
```

---

### 5. Проверка работоспособности приложения

Открыть полученный URL в браузере и убедиться, что страница apache отображается корректно.

![service_apache](./screenshots/part1/minicube_services.png)

![browser_services](./screenshots/part1/services_apache.png)

![browser_services1](./screenshots/part1/service_catalog.png)

![browser_services2](./screenshots/part1/service_customer.png)
![browser_services3](./screenshots/part1/service_order.png)

**Вывод:** Приложение доступно и корректно отвечает на запросы.

---

## Часть 2. Написание собственного манифеста

### 2.1. Структура манифестов

Для приложения из `/src/services` были написаны следующие манифесты (директория [src/kuber_manifests](./kuber_manifests)):

Предварительно были пересобраны образы

![Образы](./screenshots/part2/status/docker_images.png)

| Файл | Назначение |
|---|---|
| `configmap.yaml` | Конфигурация хостов БД и сервисов |
| `secret.yaml` | Логин/пароль БД и ключи межсервисной авторизации |
| `postgres.yaml` | Pod + Service для PostgreSQL |
| `rabbitmq.yaml` | Pod + Service для RabbitMQ |
| `booking-service.yaml`, `gateway-service.yaml`, `hotel-service.yaml`, `loyalty-service.yaml`, `payment-service.yaml`, `report-service.yaml`, `session-service.yaml` | Pod + Service для 7 модулей приложения (по одной реплике) |

---

### 2.2. Последовательное применение манифестов

Проверили статус - предварительно удалили поды из 1 части

![status](./screenshots/part2/status/status.png)

![delete_pods](./screenshots/part2/status/delete_example.png)

Проверили, что поды удалились
![status_del](./screenshots/part2/pods/pods.png)


**Команды:**
```bash
kubectl apply -f kuber_manifests/configmap.yaml
kubectl apply -f kuber_manifests/secret.yaml
kubectl apply -f kuber_manifests/postgres.yaml
kubectl apply -f kuber_manifests/rabbitmq.yaml
kubectl apply -f kuber_manifests/hotel-service.yaml
kubectl apply -f kuber_manifests/payment-service.yaml
kubectl apply -f kuber_manifests/loyalty-service.yaml 
kubectl apply -f kuber_manifests/session-service.yaml 
kubectl apply -f kuber_manifests/booking-service.yaml
kubectl apply -f kuber_manifests/report-service.yaml 
kubectl apply -f kuber_manifests/gateway-service.yaml

# Или одной командой
kubectl apply -f kuber_manifests/
```

![apply](./screenshots/part2/status/kubectl_apply.png)

---

### 2.3. Проверка статуса объектов кластера

**Команды:**

```bash
kubectl get pods
```
![pods](./screenshots/part2/status/kubectl_get_pods_services.png)

```bash
kubectl get configmap app-config
kubectl describe configmap app-config
```

![configmap](./screenshots/part2/describe/configMap.png)

```bash
kubectl get secret app-secret
kubectl describe secret app-secret
```
![secret](./screenshots/part2/describe/secret.png)

```bash
kubectl describe pod booking-service-7f95f8c66c-4sk4w
```
![booking](./screenshots/part2/pods/booking_pod.png)

```bash
kubectl describe pod gateway-service-79cbb874dd-7fkmc
```
![gateway](./screenshots/part2/pods/gateway_pod.png)

```bash
kubectl describe pod hotel-service-6f4859bdb7-sh2ht
```
![hotel](./screenshots/part2/pods/hotel_pod.png)

```bash
kubectl describe pod loyalty-service-8597d6cb96-j92p9
```
![loyalty](./screenshots/part2/pods/loylty_pod.png)

```bash
kubectl describe pod payment-service-6459d4fcb5-nqwv5
```

![payment](./screenshots/part2/pods/payment_pod.png)

```bash
kubectl describe pod postgres-cc7c5d8c6-ldfxz
```

![postgres](./screenshots/part2/pods/postgres_pod.png)

```bash
kubectl describe pod rabbitmq-786b5dc4ff-mf95r
```

![rabbit](./screenshots/part2/pods/rabbit_pod.png)

```bash
kubectl describe pod report-service-669f4665bc-x47fv
```

![report](./screenshots/part2/pods/report_pod.png)

```bash
kubectl describe pod session-service-8587c8695f-brqjj
```

![session](./screenshots/part2/pods/session_pod.png)

```bash
kubectl get services
```

![get_services](./screenshots/part2/status/kubectl_get_services.png)

```bash
kubectl describe service  booking-service
kubectl describe service  gateway-service
kubectl describe service  hotel-service
kubectl describe service  kubernetes
kubectl describe service  loyalty-service 
kubectl describe service  payment-service
kubectl describe service  postgres
kubectl describe service  rabbitmq
kubectl describe service report-service
kubectl describe service session-service
```
![describe_services-1](./screenshots/part2/describe/describe_services_1.png)
![describe_services-2](./screenshots/part2/describe/describe_services_2.png)
![describe_services-3](./screenshots/part2/describe/describe_services_3.png)

---

### 2.4. Проверка значений секретов

**Команда:**
```bash
kubectl get secret app-secret -o jsonpath='{.data.password}' | base64 --decode
kubectl get secret app-secret -o jsonpath='{.data.username}' | base64 --decode
```

![decode_secret](./screenshots/part2/status/decode_secret.png)

---

### 2.5. Проверка логов приложения

**Команда:**
```bash
kubectl logs <имя_контейнера>
# для потокового просмотра:
kubectl logs -f <имя_контейнера>

kubectl logs booking-service-7f95f8c66c-4sk4w
kubectl logs gateway-service-79cbb874dd-7fkmc
kubectl logs hotel-service-6f4859bdb7-sh2ht
kubectl logs loyalty-service-8597d6cb96-j92p9
kubectl logs payment-service-6459d4fcb5-nqwv5
kubectl logs postgres-cc7c5d8c6-ldfxz
kubectl logs rabbitmq-786b5dc4ff-mf95r
kubectl logs report-service-669f4665bc-x47fv
kubectl logs session-service-8587c8695f-brqjj
```

![logs1](./screenshots/part2/logs/logs_booking.png)
![logs2](./screenshots/part2/logs/logs_2.png)
![logs3](./screenshots/part2/logs/logs_3.png)
![logs4](./screenshots/part2/logs/logs_4.png)

---

### 2.6. Проброс туннелей к gateway service и session service

**Команды:**
```bash
minikube service gateway-service --url
```
Получили ответ:
`http://192.168.49.2:31881`

```bash
minikube service session-service --url
```
Получили ответ:
`http://192.168.49.2:31373`

Сделали проброс туннеля с компьютера на сервер
```bash
ssh -L 8081:192.168.49.2:31373 username@server -p 22
ssh -L 8087:192.168.49.2:31881 username@server -p 22
```

![urls](./screenshots/part2/url/urls.png)

---

### 2.7. Функциональные тесты Postman

**Шаги:**
- Импортировать коллекцию Postman (из первого проекта).
- Указать в переменных окружения полученные URL gateway/session сервисов.

*Настроили в постман переменые:*
- API_HOST=localhost
- USERS_PORT=8081
- GATEWAY_PORT=8087


3. Запустить Collection Runner.

Запустили коллекцию тетсов постман - получили ответ 200

![tests](./screenshots/part2/postman/tests_postman.png)

**Вывод:** _Все тесты пройдены успешно status 200

---

### 2.8. Дашборд Kubernetes

**Команда:**
```bash
minikube dashboard
```
![dashboard3](./screenshots/part2/dashboard/minikube_dashboard.png)
![dashboard1](./screenshots/part2/dashboard/dashboard_1.png)
![dashboard2](./screenshots/part2/dashboard/dashboard_2.png)
![dashboard4](./screenshots/part2/dashboard/config.png)
![dashboard5](./screenshots/part2/dashboard/services.png)
![dashboard6](./screenshots/part2/dashboard/secrets.png)


---

### 2.9. Обновление приложения и сравнение стратегий развёртывания

#### 2.9.1 Новая зависимость

Сервис для эксперимента: loyalty-service (порт 8085, БД balances_db). 
Новая зависимость: commons-lang3.
`commons-lang3` — это библиотека от Apache с набором готовых "помогающих" функций для Java, которых не хватает в стандартном языке. Ничего не запускает и не открывает сама по себе — просто добавляет в проект коробку с полезными инструментами, которыми можно пользоваться в коде

Файл: [src/services/loyalty-service/pom.xml](./services/loyalty-service/pom.xml)

```xml
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-lang3</artifactId>
    <version>3.12.0</version>
</dependency>
```
В нашем случае используется один конкретный класс из неё — StringUtils, а именно метод:
```java
StringUtils.repeat("=", 20)
```
Он просто повторяет символ "=" 20 раз и склеивает в строку — получается "====================". Без этой библиотеки пришлось бы писать такой код руками (цикл for или StringBuilder), а с ней — одна строчка.

Никакого влияния на работу самого loyalty-сервиса (базы данных, API, бизнес-логику) она не оказывает — выбрана специально как самая безобидная и не ломающая ничего зависимость, чисто для демонстрации факта "приложение обновилось"

#### 2.9.2 Использовать зависимость в коде

в файле [src/services/loyalty-service/src/main/java/com/s21/devops/sample/loyaltyservice/LoyaltyServiceApplication.java](./services/loyalty-service/src/main/java/com/s21/devops/sample/loyaltyservice/LoyaltyServiceApplication.java)

```java
package com.s21.devops.sample.loyaltyservice;

import org.apache.commons.lang3.StringUtils;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class LoyaltyServiceApplication {

    // Перед сборкой образа мы не устанавливали здесь версию v3.do10_1.0 
    // сейчас напишем новую версию сборки v3.do10_1.0
    private static final String APP_VERSION = "v4.do10";
    public static void main(String[] args) {
        System.out.println(StringUtils.repeat("=", 20)
            + " loyalty-service " + APP_VERSION + " started "
            + StringUtils.repeat("=", 20));
        SpringApplication.run(LoyaltyServiceApplication.class, args);
    }

}
```

#### 2.9.3 Создаем новый образ и пушим его

```bash
docker build -t username/loyalty-service:v4.do10 .

docker push username/loyalty-service:v4.do10

docker images
```
![images](./screenshots/part2/2_9_strategy/docker_images.png)
![docker_push](./screenshots/part2/2_9_strategy/docker_push.png)
![logs_image_version](./screenshots/part2/2_9_strategy/version_images.png)

#### 2.9.4. Стратегия Recreate

Что такое стратегия *Recreate* *RollingUpdate*
![strategy](./screenshots/part2/2_9_strategy/recreate_rooling.png)

**Манифест (фрагмент):**
Добавили стратегию
```yaml
spec:
  strategy:
    type: Recreate
```

Заменили на новый образ
```yaml
image: username/loyalty-service:v4.do10
```

в шаблоны добавили readinessProbe - проверяет готовность поды
```yaml
readinessProbe: # Добавили readinessProbe
            tcpSocket:
              port: 8085
            initialDelaySeconds: 1
            periodSeconds: 2
            failureThreshold: 30

```
манифест  [loyalty-service-recreate](../src/kuber_manifests/strategies/loyalty-service-recreate.yaml)

Для замера времени развертывания , времени недоступности приложения подготовили скрипт
и запустили скрипт

**Результат:** 

![recreate_pods](./screenshots/part2/2_9_strategy/get_pods_recreating.png)
![recreate_apply](./screenshots/part2/2_9_strategy/recreating.png)


#### 2.9.5. Стратегия Rolling Update

**Манифест (фрагмент):**
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
```

Заменили на новый образ
```yaml
image: username/loyalty-service:v4.do10
```

в шаблоны добавили readinessProbe - проверяет готовность поды
```yaml
readinessProbe: # Добавили readinessProbe
            tcpSocket:
              port: 8085
            initialDelaySeconds: 1
            periodSeconds: 2
            failureThreshold: 30

```

манифест [loyalty-service-rolling](./kuber_manifests/strategies/loyalty-service-rolling.yaml)

Для замера времени развертывания , времени недоступности приложения подготовили скрипт
и запустили скрипт

**Результат:** 

![rolling_pods](./screenshots/part2/2_9_strategy/get_pods_rolling.png)
![rolling_apply](./screenshots/part2/2_9_strategy/rolling.png)

#### 2.9.6. Сравнение стратегий Recreate и RollingUpdate

| Показатель                          |                          **Recreate** |                       **RollingUpdate** |
| ----------------------------------- | ------------------------------------: | --------------------------------------: |
| Реплик                              |                                     1 |                                       1 |
| Время переразвертывания             |                           **64,55 с** |                             **63,71 с** |
| HTTP-запросов во время теста        |                               **214** |                                 **310** |
| Периодов недоступности              |                                 **1** |                                   **2** |
| Суммарный downtime                  |                           **64,70 с** |                              **0,92 с** |
| Максимальный непрерывный downtime   |                           **64,70 с** |                              **0,71 с** |
| Простой во время запуска нового Pod | **Да, практически всё время запуска** | **Нет, старый Pod продолжает работать** |

### Вывод

При стратегии **Recreate** старый Pod удаляется до запуска нового, поэтому при одной реплике сервис был недоступен **64,70 с**. При **RollingUpdate** новый Pod запускался около **63,71 с**, но старый продолжал обслуживать запросы, поэтому фактический downtime составил всего **0,92 с**, а максимальный непрерывный обрыв — **0,71 с**. Таким образом, **RollingUpdate значительно лучше для обеспечения доступности сервиса**, несмотря на практически одинаковое общее время переразвертывания. **Recreate проще, но приводит к длительному простою; RollingUpdate позволяет выполнить обновление практически без остановки сервиса.**

Стратегия **RollingUpdate** имеет свои преимущества и недостатки
*Преимущества*:
При обновлении Pods практические всегда доступны с "нулевым" downtime 

*Недостатки:;
- Потребление ресурсов CPU/RAM: 
Так как вы разрешаете maxSurge: 1, убедитесь, что в вашем кластере есть запас CPU/RAM, чтобы временно запустить лишний Pod. Если ресурсов нет, обновление зависнет в состоянии Pending.

- Обязательные проверки: Чтобы эта схема работала, у вас должны быть настроены readinessProbe (проверка готовности). Без них новый Pod может считаться "готовым" сразу после запуска контейнера, даже если приложение внутри еще не стартовало, что приведет к ошибкам 5xx.


---

## Заключение

Все задания проекта выполнены 
