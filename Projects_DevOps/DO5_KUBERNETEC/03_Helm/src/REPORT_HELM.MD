# Helm и Kustomization


## Введение

Kubernetes — одна из быстро развивающихся технологий, и в настоящее время все компании внедряют ее. Когда ты запускаешь любое приложение в Kubernetes, тебе нужно развернуть очень много объектов, таких как развертывание, карта конфигурации, секреты и т. д. Тебе нужно определить все эти объекты в файле manifest.yml и отправить эти файлы на сервер API Kubernetes. Kubernetes читает эти файлы манифеста и создает нужные объекты.

Однократное развертывание приложения — это нормально, но если ты хочешь развертывать приложение снова и снова, тебе нужно снова и снова отправлять все файлы манифеста на сервер API Kubernetes. Helm — это инструмент, решающий эту проблему.

**Helm** — это менеджер пакетов для Kubernetes, который предоставляет решение для управления пакетами, безопасности и настройки при развертывании приложений в Kubernetes. Helm упрощает работу с Kubernetes.

В то же время **Kustomize** становится все более популярным инструментом для управления манифестами Kubernetes. Вместо использования шаблонов, как это делает Helm, Kustomize работает, опираясь на существующие манифесты. Используя этот шаблон, он предоставляет различные функции, включая пространство имен ресурсов, изменение метаданных и создание секретов Kubernetes — и все это без редактирования исходных манифестов.


## Часть 1. Развертывание приложения с помощью Kustomize

### Задание 1.1. Получить набор виртуальных машин с развернутым кластером.

| Роль        | Кол-во | Назначение                                        |
|-------------|--------|----------------------------------------------------|
| `helm-master`  | 1      | control-plane (`k3s server`), Ingress, cert-manager |
| `helm-worker-1`  | 1      | рабочий узел (`k3s agent`)                          |
| `helm-worker-2`  | 1      | рабочий узел (`k3s agent`)                          |

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

Поднимим 3 виртуальные машины (Ubuntu 22.04 LTS, ≥2 vCPU / 2 GB RAM каждая) локально через `multipass`

```bash
# Пример для multipass (локальный вариант)
multipass launch --name helm-master --cpus 2 --memory 2G --disk 10G 22.04
multipass launch --name helm-worker-1 --cpus 2 --memory 2G --disk 10G 22.04
multipass launch --name helm-worker-2 --cpus 2 --memory 2G --disk 10G 22.04
multipass list
```
Установить k3s на всех трёх машинах без Traefik

На **мастере**:

```bash
multipass exec helm-master -- curl -sfL https://get.k3s.io | sh -s - server \
  --disable=traefik \
  --write-kubeconfig-mode=644
```

Проверка версии и статуса на мастере:

```bash
multipass exec helm-master -- sudo systemctl status k3s
multipass exec helm-master -- k3s --version
multipass exec helm-master -- sudo k3s kubectl get nodes
```

Получаем токен на мастере:

```bash
multipass exec helm-master -- sudo cat /var/lib/rancher/k3s/server/node-token

export NODE_TOKEN=101zzzzzzz
export MASTER_IP=10.181.19.242
```
```bash
# на worker-1:
multipass exec helm-worker-1 -- curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${NODE_TOKEN} sh -

# на worker-2:
multipass exec helm-worker-1 -- curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${NODE_TOKEN} sh -
```

Проверяем:
```bash
multipass exec helm-master -- sudo k3s kubectl get nodes -o wide
```
![VMs](./screenshots/part1/vms_up.png)

### Задание 1.2. Перенести манифесты из предыдущих блоков.

Перенесли манифесты из предыдущего проекта [src/manifests](./manifests/)

### Задание 1.3. Установить *kustomize* на локальной машине.

```bash
sudo apt update
sudo apt install -y kustomize
kustomize --version
```

### Задание 1.4. Cоздать скелет проекта развертывания с одной базовой конфигурацией (base) и одной оверлейной конфигурацией (production):

```bash
mkdir -p src/kustomize/base
mkdir -p src/kustomize/overlays/production

nano src/kustomize/basekustomization.yaml
```
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - booking-service.yaml
  - gateway-service.yaml
  - hotel-service.yaml
  - loyalty-service.yaml
  - payment-service.yaml
  - postgres-pvc.yaml
  - postgres.yaml
  - rabbitmq.yaml
  - report-service.yaml
  - session-service.yaml
  - ingress.yaml
```
```bash
touch src/kustomize/overlays/production/kustomization.yaml
touch src/kustomize/overlays/production/configMap.yaml
touch src/kustomize/overlays/production/secret.yaml
touch src/kustomize/overlays/production/replicas-patch.yaml

touch src/kustomize/kustomization.yaml
```


```
tree ./
./
├── base
│   ├── booking-service.yaml
│   ├── gateway-service.yaml
│   ├── hotel-service.yaml
│   ├── ingress.yaml
│   ├── kustomization.yaml
│   ├── loyalty-service.yaml
│   ├── payment-service.yaml
│   ├── postgres-pvc.yaml
│   ├── postgres.yaml
│   ├── rabbitmq.yaml
│   ├── report-service.yaml
│   └── session-service.yaml
├── kustomization.yaml
└── overlays
    └── production
        ├── configMap.yaml
        ├── kustomization.yaml
        ├── replicas-patch.yaml
        └── secret.yaml

4 directories, 17 files
```

### Задание 1.5. Написать базовые и оверлейные конфигурации для kustomize. В базовых указать сервисы и развертывания, в production добавить конкретные секреты и конфигурационные значения.

```bash
cp src/manifests/configmap.yaml \
   src/kustomize/overlays/production/configMap.yaml

cp src/manifests/secret.yaml \
   src/kustomize/overlays/production/secret.yaml
```
- Заполняем production/kustomization.yaml
- Заполняем корневой kustomization.yaml

### Задание 1.6. Создать `replicas-patch.yaml` для оверлей production, который модифицирует количество реплик для деплоймента gateway service до 3 реплик.

- Создаём replicas-patch.yaml
 
### Задание 1.7. Собрать результирующий конфигурационный файл, учитывая оверлей `production`.

- Создаем ingress controller

```bash
multipass exec helm-master -- sudo k3s kubectl apply \
  -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.3/deploy/static/provider/baremetal/deploy.yaml
```
- Проверяем
```bash
multipass exec helm-master -- sudo k3s kubectl get pods -n ingress-nginx
multipass exec helm-master -- sudo k3s kubectl get svc -n ingress-nginx
```

![ingress](./screenshots/part1/ingress.png)

- Устанавливаем сертификат
```bash
multipass exec helm-master -- sudo k3s kubectl apply \
  -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.4/cert-manager.yaml
```

- Применим
```bash
multipass exec helm-master -- sudo k3s kubectl apply \
  -f /home/ubuntu/do11/k8s/cert-manager-selfsigned.yaml \
  -f /home/ubuntu/do11/k8s/root-ca.yaml \
  -f /home/ubuntu/do11/k8s/ca-issuer.yaml \
  -f /home/ubuntu/do11/k8s/wildcard-certificate.yaml
```

- Проверим
```bash
multipass exec helm-master -- sudo k3s kubectl get clusterissuer
multipass exec helm-master -- sudo k3s kubectl get certificate
multipass exec helm-master -- sudo k3s kubectl get secret wildcard-k8s-local-tls
```

![cert](./screenshots/part1/cert_manager.png)

```bash
kustomize build src/kustomize > src/kustomize/production.yaml
```

![build_1](./screenshots/part1/kustomize_build_1.png)
![build_2](./screenshots/part1/kustomize_build_2.png)

- Собрали результирующий конфигурационный файл [production.yaml](./kustomize/production.yaml)

- Перенесем файл на helm-master `~/projects/DO12/kustomize$`
```bash
multipass transfer production.yaml helm-master:/home/ubuntu/do12/
```

- Запустили приложение на helm-master

```bash
multipass exec helm-master -- sudo k3s kubectl apply -f /home/ubuntu/do12/production.yaml
```
![apply](./screenshots/part1/1_7_kubectl_production.png)

- Проверям результат
```bash
multipass exec helm-master -- sudo k3s kubectl get pods -o wide
multipass exec helm-master -- sudo k3s kubectl get svc
multipass exec helm-master -- sudo k3s kubectl get deployment
multipass exec helm-master -- sudo k3s kubectl get ingress
```

![results](./screenshots/part1/1_7_status_deployment.png)


### Задание 1.8. Запустить функциональные тесты Postman и удостовериться в работоспособности приложения.

- Проверим какой слушает порт 
```bash
multipass exec helm-master -- sudo k3s kubectl get svc -n ingress-nginx
```

```
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.43.219.50    <none>        80:31142/TCP,443:32095/TCP   12h
ingress-nginx-controller-admission   ClusterIP   10.43.149.139   <none>        443/TCP
``` 

- Пробросим туннель 
```bash
ssh -N -L 32095:10.181.19.225:32095 username@host -p 2022
```

Файл коллекции: `src/application_tests.postman_collection.json`.
Перед прогоном поменяй переменные окружения коллекции:

| Переменная      | Новое значение   |
|-----------------|------------------|
| `API_HOST`      | `https://app.k8s.local`|
| `GATEWAY_PORT`  | `32095` (запросы идут через `https://`)|
| `USERS_PORT`    | `32095`                                |


> С прошлого задания были добавлен на Mac в /etc/hosts добавляем:
`127.0.0.1 app.k8s.local`

> И пробросили туннель до сервера  где Multipass-сеть — 10.181.19.0/24 `ssh -N -L 32095:10.181.19.225:32095 username@host -p 2022`


![8_postman](./screenshots/part1/1_8_postman.png)

*Функциональные тесты приложения были выполнены через Nginx Ingress Controller по адресу https://app.k8s.local:32095. В ходе тестирования успешно выполнены операции авторизации пользователя, получения списка отелей, получения информации об отеле, бронирования и получения бонусного баланса пользователя. Всего выполнено 5 тестов: 5 успешно, 0 неуспешно.*

## Часть 2. Развертывание приложения с помощью Helm

### Задание 2.1. Получить набор виртуальных машин с развернутым кластером.

- Склонировали и подняли виртаульные машины с развернутым кластером
![VMs_up](./screenshots/part2/2_1_VMs_up.png)

### Задание 2.2. Перенести манифесты из предыдущих блоков.

- выполнено

### Задание 2.3. Установить *helm* на локальной машине и удостовериться, что этот инструмент имеет валидное подключение к полученному удаленному кластеру Kubernetes.

- Установили 'helm'
![helm](./screenshots/part2/2_3_helm_install.png)

- Проверили валидное подключение к полученному удаленному кластеру Kubernetes
```bash
helm list -A
```
- настроили конфиг
```bash
multipass exec helm2-master1 -- sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/helm2.yaml

nano ~/.kube/helm2.yaml
```
[helm2.yaml](./kube_config/helm2.yaml)

- Заменили
```yaml
server: https://127.0.0.1:6443
# на

server: https://10.181.19.105:6443
```

![helm2](./screenshots/part2/2_3_kube_config_helm2.png)

### Задание 2.4. Создать *helm*-чарты и шаблоны для своего приложения с помощью команды `helm create`. Эта команда создаст базовую структуру чарта с шаблонами для ресурсов: deployment, service и ingress.

- Создали `helm`-chart
```bash
helm create app-hotel
```

![app-hotel](./screenshots/part2/2_4_helm_create_app-hotel.png)

### Задание 2.5. Отредактировать файл `values.yaml` на диаграмме, чтобы указать параметры конфигурации для твоего приложения, необходимые для создания манифестов Kubernetes для указанных развертываний (deployments). Описать объекты развертывания и сервисов в директории шаблонов (templates).

- создаем единный шаблон для 7 сервисов [services.yaml](./app-hotel/templates/services.yaml)

```bash
nano app-hotel/templates/services.yaml
```
- создаем шаблон для postgres и rabbitMQ

```bash
nano app-hotel/templates/postgres.yaml

nano app-hotel/templates/postgres-pvc.yaml

nano app-hotel/templates/rabbitmq.yaml
```

- создаем шаблон для ingress
```bash
nano app-hotel/templates/ingress.yaml
```

- создаем шаблон configMap
```bash
nano app-hotel/templates/configmap.yaml
```

- создаем пеерменные для каждого сервиса [values.yaml](./app-hotel/values.yaml)
```bash
nano app-hotel/values.yaml
```

- проверим
```bash
helm lint app-hotel
```

- Запишем в файл 
```bash
helm template app-hotel ./app-hotel > tmp/app-hotel-rendered.yaml
```

![helm_lint](./screenshots/part2/2_5_helm_lint.png)


### Задание 2.6. Упаковать *helm*-чарт с помощью команды `helm package` для создания файла `*.tgz`, содержащего чарт и его зависимости.

```bash
helm package app-hotel
```
![helm package](./screenshots/part2/2_6_package.png)


### Задание 2.7. Развернуть *helm*-чарт в кластере Kubernetes с помощью команды `helm install`. Указать произвольный `namespace` и `release-name`.

Helm **не будет хранить `app-secret`**

Сначала создаём `app-secret` в namespace `hotel`.

- Создаём namespace

```bash
KUBECONFIG=~/.kube/helm2.yaml kubectl create namespace hotel
```

- Создаём Secret

Для начала перенесём текущий учебный Secret **без изменения значений**.

Самый удобный способ — взять существующий файл:
```bash
KUBECONFIG=~/.kube/helm2.yaml kubectl apply -n hotel -f manifests/secret.yaml
```

- Проверить
```bash
KUBECONFIG=~/.kube/helm2.yaml kubectl get secret app-secret -n hotel
```

- Важно:

`app-secret` теперь находится **только в namespace `hotel`**:
```text
cluster
└── hotel
    └── app-secret
```

![app-secret](./screenshots/part2/2_7_appsecret.png)


- Установка `helm install` 
```bash
KUBECONFIG=~/.kube/helm2.yaml helm install hotel-release ./app-hotel-0.1.0.tgz -n hotel
```

![helm_install](./screenshots/part2/2_7_helm_install.png)

### Задание 2.8. Проверить статус развернутого приложения при помощи команды `kubectl get`. Результаты представить в отчете.


- Проверим
```bash
KUBECONFIG=~/.kube/helm2.yaml helm list -n hotel
KUBECONFIG=~/.kube/helm2.yaml kubectl get all -n hotel
KUBECONFIG=~/.kube/helm2.yaml kubectl get pods -n hotel -o wide
KUBECONFIG=~/.kube/helm2.yaml kubectl get pvc -n hotel
KUBECONFIG=~/.kube/helm2.yaml kubectl get ingress -n hotel

KUBECONFIG=~/.kube/helm2.yaml helm status hotel-release -n hotel
```
![1](./screenshots/part2/2_7_get_all_list.png)
![2](./screenshots/part2/2_7_get_pods.png)
![3](./screenshots/part2/2_7_status.png)


### Задание 2.9. Внести как минимум одно изменение в `values.yaml` и выполнить команду `helm upgrade`. 

- Внесем изменение по количеству реплик для loyalty - 3 и report - 2
- Проверим `helm lint app-hotel`
- Выполним upgrade
```bash
KUBECONFIG=~/.kube/helm2.yaml helm upgrade hotel-release ./app-hotel -n hotel
```

![upgrade](./screenshots/part2/2_9_upgrade_helm.png)

### Задание 2.10. Запустить функциональные тесты Postman и удостовериться в работоспособности приложения.

- Проверим какой слушает адрес и порт 
```bash
KUBECONFIG=~/.kube/helm2.yaml kubectl get ingress -n hotel
KUBECONFIG=~/.kube/helm2.yaml kubectl get svc -n ingress-nginx
```

```
------------------------------------------------------------------------
NAME              CLASS   HOSTS           ADDRESS         PORTS     AGE
gateway-ingress   nginx   app.k8s.local   10.181.19.105   80, 443   23m

------------------------------------------------------------------------------------------------------------------
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.43.245.155   <none>        80:31916/TCP,443:30619/TCP   5m14s
ingress-nginx-controller-admission   ClusterIP   10.43.45.103    <none>        443/TCP                      5m14s

``` 

![ip](./screenshots/part2/2_10_ingress_ip.png)
![port](./screenshots/part2/2_10_ingress_port.png)


- Пробросим туннель 
```bash
ssh -N -L 30619:10.181.19.105:30619 username@host -p 2022
```

Файл коллекции: `src/application_tests.postman_collection.json`.
Перед прогоном поменяй переменные окружения коллекции:

| Переменная      | Новое значение   |
|-----------------|------------------|
| `API_HOST`      | `https://app.k8s.local`|
| `GATEWAY_PORT`  | `30619` (запросы идут через `https://`)|
| `USERS_PORT`    | `30619`                                |

![postman_2](./screenshots/part2/2_10_postman.png)

*Функциональные тесты приложения были выполнены через Nginx Ingress Controller по адресу https://app.k8s.local:32095. В ходе тестирования успешно выполнены операции авторизации пользователя, получения списка отелей, получения информации об отеле, бронирования и получения бонусного баланса пользователя. Всего выполнено 5 тестов: 5 успешно, 0 неуспешно.*

## Заключение

Выполнили все задания и отразили в отчете - развернули Виртуальные машины с кластерами, отработали практически навыки управления через шаблоны `Kustomize` и `Helm` 

