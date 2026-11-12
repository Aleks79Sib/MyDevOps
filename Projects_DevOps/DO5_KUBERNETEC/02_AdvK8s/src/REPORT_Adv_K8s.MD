# Advanced Kubernetes. Развертывание собственного кластера k3s

## Описание решения

| Роль        | Кол-во | Назначение                                        |
|-------------|--------|----------------------------------------------------|
| `master-1`  | 1      | control-plane (`k3s server`), Ingress, cert-manager |
| `worker-1`  | 1      | рабочий узел (`k3s agent`)                          |
| `worker-2`  | 1      | рабочий узел (`k3s agent`)                          |

Приложение — микросервисная система бронирования отелей из 7 Spring Boot
сервисов (`session`, `hotel`, `booking`, `payment`, `loyalty`, `report`,
`gateway`), PostgreSQL и RabbitMQ. Порты сервисов:

| Сервис            | Порт |
|-------------------|------|
| session-service   | 8081 |
| hotel-service      | 8082 |
| booking-service    | 8083 |
| payment-service    | 8084 |
| loyalty-service    | 8085 |
| report-service     | 8086 |
| gateway-service    | 8087 |

---

## 1. Получить набор виртуальных машин для кластера

Поднимим 3 виртуальные машины (Ubuntu 22.04 LTS, ≥2 vCPU / 2 GB RAM каждая) локально через `multipass`

```bash
# Пример для multipass (локальный вариант)
multipass launch --name master-1 --cpus 2 --memory 2G --disk 10G 22.04
multipass launch --name worker-1 --cpus 2 --memory 2G --disk 10G 22.04
multipass launch --name worker-2 --cpus 2 --memory 2G --disk 10G 22.04
multipass list
```
![vms](./screenshots/vms_up.png)
---

## 2. Установить k3s на всех трёх машинах без Traefik

На **мастере**:

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --disable=traefik \
  --write-kubeconfig-mode=644
```

Проверка версии и статуса на мастере:

```bash
sudo systemctl status k3s
k3s --version
sudo k3s kubectl get nodes
```

![k3s_master-1](./screenshots/k3s_master-1.png)

---

## 3. Подключить узлы к кластеру через `k3s server`/`k3s agent`, `--token`, `--server`

Получаем токен на мастере:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Экспортируем как переменную окружения и подключаем воркеры:

```bash
export NODE_TOKEN=<значение из /var/lib/rancher/k3s/server/node-token>
export NODE_TOKEN=101ababa5d4a55cc762d697f1491f52bc6203002c4448c0fb9b63caccc0853c0a3::server:966de453efb69dd301a5220a0bbd4f83
export MASTER_IP=10.181.19.242

# на worker-1 и worker-2:
curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${NODE_TOKEN} sh -
```

![w1](./screenshots/worker-1.png)
![w2](./screenshots/worker-2.png)

Если нужно поднять ещё один server-узел (для отказоустойчивого
control-plane), используется:

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --server https://${MASTER_IP}:6443 \
  --token ${NODE_TOKEN} \
  --disable=traefik
```

Проверяем, что все три узла в кластере:

```bash
sudo k3s kubectl get nodes -o wide
```
![pods](./screenshots/get_pods.png)

---

## 4. Установить Ingress Controller Nginx вместо стандартного

Используем официальный манифест ingress-nginx

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/baremetal/deploy.yaml

# ждём, пока поднимется контроллер
kubectl get pods -n ingress-nginx -w
```

![install_nginx](./screenshots/4_install_nginx.png)

```bash
kubectl -n ingress-nginx patch svc ingress-nginx-controller \
  -p '{"spec": {"type": "NodePort"}}'
kubectl -n ingress-nginx get svc ingress-nginx-controller
```

![nginx_running](./screenshots/4_1_nginx_running.png)

<!-- Если внешний IP всё-таки нужен напрямую на 80/443 — пробрось порты 80/443 с
узла (или используй `hostNetwork: true` в деплойменте контроллера) на IP
мастера, на который будет указывать домен. -->

---

## 5. Получить домен и настроить cert-manager для wildcard-сертификата

*Вариант 1 доменное имя local с самоподписанным сертификатом *:

Будем использовать вымышленный локальный домен:

`k8s.local`

Wildcard:

`*.k8s.local`

Например, приложение потом будет доступно как:

`app.k8s.local`

Схема:

```txt
cert-manager
     │
     ▼
SelfSigned ClusterIssuer
     │
     ▼
Root CA Certificate
     │
     ▼
CA ClusterIssuer
     │
     ▼
Wildcard Certificate
     │
     ▼
Secret: wildcard-k8s-local-tls
     │
     ▼
Nginx Ingress
```

*Это соответствует идее cert-manager из учебного материала: автоматическое управление TLS-сертификатами Kubernetes и интеграция с Ingress* [01-kubernetes_rus.md](../materials/01-kubernetes_rus.md)


*Вариант 2* приобретение домена
1. Зарегистрируй домен (например, на любом бесплатном/платном регистраторе)
   или используй поддомен от бесплатного DNS-сервиса, поддерживающего API
   (Cloudflare, DuckDNS + webhook, etc.) — **DNS-01 challenge обязателен**,
   так как HTTP-01 не поддерживает wildcard-сертификаты.
2. Пропиши A-запись `<домен>` → публичный IP мастера, и (если DNS позволяет)
   `*.<домен>` → тот же IP.

### 5.1 Установка cert-manager:

на master-1:

```bash
multipass exec master-1 -- sudo k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.4/cert-manager.yaml

# Проверяем:
multipass exec master-1 -- kubectl get pods -n cert-manager -w
```

![cert_manager](./screenshots/5_1_cert_manager.png)

### 5.2. Создать SelfSigned ClusterIssuer

- Создадим файл: [src/k8s/cert-manager-selfsigned.yaml](./k8s/cert-manager-selfsigned.yaml)

Скопируем на master-1:

> *Примечание* если multipass установлен через snap - то копирование файлов не из директории /home будет не доступно - либо дайте права либо копируйте через /home

```bash
multipass transfer -r ~/projects/DO11/src/k8s master-1:/home/ubuntu/do11/
```

![transfer_file](./screenshots/5_2_transfer_file.png)

Применяем:

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/do11/k8s/cert-manager-selfsigned.yaml
```

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get clusterissuer
```

![apply_cert](./screenshots/5_2_1_apply_cert.png)

### 5.3. Создать Root CA Certificate

Теперь cert-manager сам создаст наш корневой CA.

Создаём: [src/k8s/root-ca.yaml](./k8s/root-ca.yaml)


Применяем:

```bash
multipass transfer src/k8s/root-ca.yaml master-1:
```

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/do11/k8s/root-ca.yaml
```

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get certificate -n cert-manager
```

Должно быть примерно:

```text
NAME      READY   SECRET           AGE
root-ca   True    root-ca-secret   2m1s
```

И:

```bash
multipass exec master-1 -- sudo k3s kubectl get secret -n cert-manager
```

Должен появиться:

```text
NAME                      TYPE                DATA   AGE
cert-manager-webhook-ca   Opaque              3      53m
root-ca-secret            kubernetes.io/tls   3      2m35s
```

![root_ca](./screenshots/5_3_root_ca.png)

---

### 5.4. Создать CA ClusterIssuer

Теперь `root-ca-secret` будет использоваться как наш локальный центр сертификации.

Создаём:

```text
[src/k3s/ca-issuer.yaml](./k3s/ca-issuer.yaml)
```

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: root-ca-secret
```

Применяем:

```bash
multipass transfer src/k8s/ca-issuer.yaml master-1:
```

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/do11/k8s/ca-issuer.yaml
```

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get clusterissuer
```

Получаем:

```text
NAME                READY
selfsigned-issuer   True
ca-issuer           True
```

![ca-issuer](./screenshots/5_4_ca_issuer.png)

---

### 5.5. Создать wildcard Certificate

Создаём:

```text
[src/k8s/wildcard-certificate.yaml](./k3s/wildcard-certificate.yaml)
```

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-k8s-local
  namespace: default
spec:
  secretName: wildcard-k8s-local-tls

  issuerRef:
    name: ca-issuer
    kind: ClusterIssuer
    group: cert-manager.io

  commonName: "*.k8s.local"

  dnsNames:
    - "*.k8s.local"
    - "k8s.local"

  duration: 2160h
  renewBefore: 360h

  privateKey:
    algorithm: RSA
    size: 2048
```

Применяем:

```bash
multipass transfer src/k8s/wildcard-certificate.yaml master-1:
```

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/do11/k8s/wildcard-certificate.yaml
```

Проверяем

```bash
multipass exec master-1 -- sudo k3s kubectl get certificate
```

Получаем:

```text
NAME                 READY   SECRET                    AGE
wildcard-k8s-local   True    wildcard-k8s-local-tls    ...
```

![wildcard](./screenshots/5_5_wildcard-k8s.png)

Очень важная проверка:

```bash
multipass exec master-1 -- sudo k3s kubectl describe certificate wildcard-k8s-local
```

И:

```bash
multipass exec master-1 -- sudo k3s kubectl get secret wildcard-k8s-local-tls
```

Получаем:

```text
NAME                     TYPE                DATA   AGE
wildcard-k8s-local-tls   kubernetes.io/tls   3      3m1s
```
— **пункт 5 фактически выполнен**.

<!-- **Использовать Secret в Ingress**

Теперь создаём Ingress.

Но здесь есть важный момент: **пока у тебя ещё нет приложения и его Service**.

Поэтому сейчас нельзя написать:

```yaml
backend:
  service:
    name: my-service
```

потому что такого Service пока нет.

Он появится на пунктах 7–8 задания.

Поэтому **сам Ingress мы лучше создадим после того, как появится приложение**.

Но сам TLS будет готов уже сейчас. -->

---

<!-- **Настроить локальное имя**

Когда появится приложение, допустим:

```text
app.k8s.local
```

На **твоём основном компьютере**, а не внутри VM, добавишь в `/etc/hosts`:

```text
10.181.19.242 app.k8s.local
```

Но тут есть нюанс с NodePort.

Сейчас Nginx слушает:

```text
32512
31152
```

Поэтому непосредственно:

```text
https://app.k8s.local
```

не попадёт на `31152`, если перед ним нет дополнительного NAT/port-forward.

Для лаборатории можно обращаться:

```text
https://app.k8s.local:31152
```

А если захочешь красивый вариант без порта:

```text
https://app.k8s.local
```
можно отдельно настроить проброс `443 → 31152`. -->


## 6. Создать Ingress-ресурс для домена с nginx ingress controller и сертификатом

Создаем манифест: [ingress](./k8s/ingress.yaml)

---

## 7. Создать PV для БД PostgreSQL

PV/PVC для PostgreSQL из десятого проекта уже описаны в
`postgres.yaml` скопируем из DO10

Создаем: [postgres-pvc.yaml](./k8s/postgres-pvc.yaml)

У нас k3s уже содержит local-path-provisioner, поэтому Kubernetes сам создаст PV.

Меняем:
[postgres.yaml](./k8s/postgres.yaml)

В Deployment PostgreSQL добавляем к существующим volumeMounts:
```yaml
- name: postgres-data
  mountPath: /var/lib/postgresql/data
```
И в volumes добавляем:
```yaml
- name: postgres-data
  persistentVolumeClaim:
    claimName: postgres-pvc
```
Скопируем файлы на VM

Порядок запуска:

```bash
multipass exec master-1 -- sudo k3s kubectl apply -f /home/ubuntu/do11/k8s/configmap.yaml
multipass exec master-1 -- sudo k3s kubectl apply -f /home/ubuntu/do11/k8s/secret.yaml

# PVC
multipass exec master-1 -- sudo k3s kubectl apply -f /home/ubuntu/do11/k8s/postgres-pvc.yaml
multipass exec master-1 -- sudo k3s kubectl apply -f /home/ubuntu/do11/k8s/postgres.yaml

multipass exec master-1 -- sudo k3s kubectl apply -f /home/ubuntu/do11/k8s/rabbitmq.yaml
```

Проверка:
```bash
multipass exec master-1 -- sudo k3s kubectl get pv,pvc

multipass exec master-1 -- sudo k3s kubectl get pods
```

![pv_pvc](./screenshots/6_pv_pvc_postgres_rq.png)

---

## 8. Запустить приложение, описанное в манифесте

> *Примечание*: Скопировали манифесты из DO10 и внесли изменения session-service.yaml  gateway-service.yaml и заменили на ClusterIP вместо NodePort

Запуск приложения все микросервисы:
```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/do11/k8s/session-service.yaml \
  -f /home/ubuntu/do11/k8s/hotel-service.yaml \
  -f /home/ubuntu/do11/k8s/booking-service.yaml \
  -f /home/ubuntu/do11/k8s/payment-service.yaml \
  -f /home/ubuntu/do11/k8s/loyalty-service.yaml \
  -f /home/ubuntu/do11/k8s/report-service.yaml \
  -f /home/ubuntu/do11/k8s/gateway-service.yaml
```

![apply_services](./screenshots/8_apply_services.png)

Проверяем:
```bash
multipass exec master-1 -- sudo k3s kubectl get pods -o wide

multipass exec master-1 -- sudo k3s kubectl get svc
```

![status](./screenshots/8_status_pods.png)

**После запуска приложения — применяем Ingress**

Когда gateway-service существует:

```bash
multipass exec master-1 -- sudo k3s kubectl apply -f /home/ubuntu/do11/k8s/ingress.yaml

multipass exec master-1 -- sudo k3s kubectl get ingress
```

![ingress](./screenshots/7_ingress.png)

---

## 9. Запустить функциональные тесты Postman и убедиться в работоспособности

Файл коллекции: `src/application_tests.postman_collection.json`.
Перед прогоном поменяй переменные окружения коллекции:

| Переменная      | Старое значение | Новое значение                     |
|-----------------|------------------|-------------------------------------|
| `API_HOST`      | `localhost`      | `https://app.k8s.local`              |
| `GATEWAY_PORT`  | `8087`           | `31152` (запросы идут через `https://`)|
| `USERS_PORT`    | `8081`           | `31152`                                |

> *Примечание*: Так как Ingress маршрутизирует по путям (`/api/v1/gateway`, `/api/v1/auth`),
> а не по портам, проще всего продублировать коллекцию с явными `https://`
> URL или через Postman Runner подставить `baseUrl` окружения.

> Добавили наше доменное имя на mac чтобы резолвился адрес `app.k8s.local`- так мы не использовали DNS провайдера (использовали сертификат self-signed)

> Для этого на Mac в /etc/hosts добавляем:
`127.0.0.1 app.k8s.local`

> И пробросили туннель до сервера  где Multipass-сеть — 10.181.19.0/24 `ssh -N -L 31152:10.181.19.241:31152 username@host -p 2022`

![9_postman](./screenshots/9_postman.png)

*Функциональные тесты приложения были выполнены через Nginx Ingress Controller по адресу https://app.k8s.local:31152. В ходе тестирования успешно выполнены операции авторизации пользователя, получения списка отелей, получения информации об отеле, бронирования и получения бонусного баланса пользователя. Всего выполнено 5 тестов: 5 успешно, 0 неуспешно.*

---

## 10. Установить и запустить Prometheus Operator, `kubectl get pods -n monitoring`

> **Примечание**: Официальная документация Prometheus Operator прямо предусматривает установку **обычными YAML-файлами**: сначала CRD и сам Operator с необходимыми RBAC-ресурсами. [Prometheus Operator](https://prometheus-operator.dev/docs/getting-started/installation/)

> У нас Kubernetes `v1.36.3`, поэтому текущая версия Operator подходит: для Operator `v0.84.0+` требуется Kubernetes ≥1.25, а актуальный релиз сейчас `v0.93.1`- использовать будем `v0.93.0`

- Создаём namespace `monitoring`

```bash
multipass exec master-1 -- sudo k3s kubectl create namespace monitoring
```

Проверка:

```bash
multipass exec master-1 -- sudo k3s kubectl get namespace monitoring
```

- Скачиваем официальный `bundle.yaml` -аккуратно весит > 4 mb (74 тыс строк кода)

На `master-1`:

```bash
multipass exec master-1 -- bash -c 'curl -L https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.93.0/bundle.yaml -o /home/ubuntu/do11/k8s/prometheus-operator.yaml'
```
- Или попробовать собрать минимальную версию 

Проверить:

```bash
multipass exec master-1 -- ls -lh /home/ubuntu/do11/k8s/prometheus-operator.yaml
```

- Применяем манифест - *Или попробовать собрать минимальную версию* 

```bash
multipass exec master-1 -- sudo k3s kubectl apply -n monitoring -f /home/ubuntu/do11/k8s/prometheus-operator.yaml
```
- Может зависнуть терминал

- Проверяем только  CRD

```bash
multipass exec master-1 -- sudo k3s kubectl get crd | grep monitoring.coreos.com
```

- Проверяем, что ресурсы создались

```bash
multipass exec master-1 -- sudo k3s kubectl get pods -n monitoring
```

И отдельно:

```bash
multipass exec master-1 -- sudo k3s kubectl get deployments -n monitoring
```

- Если Pod Operator не появился в `monitoring` 

- Применим кастомный манифест

```bash
multipass exec master-1 -- sudo k3s kubectl apply -f /home/ubuntu/do11/k8s prometheus-operator-monitoring.yaml
```

- Проверим `monitoring`

```bash
multipass exec master-1 -- sudo k3s kubectl get pods -n monitoring
```

![monitoring](./screenshots/10_monitoring.png)

---

## Заключение 

Все задания в рамка этого проекта выполнены и предоставлены в отчете 



