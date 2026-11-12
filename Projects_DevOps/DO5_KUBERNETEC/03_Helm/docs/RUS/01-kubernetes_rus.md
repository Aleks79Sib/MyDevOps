# Helm и Kustomize

Helm и Kustomize — это инструменты для управления конфигурацией Kubernetes.

**Helm** — это пакетный менеджер для Kubernetes, который позволяет упаковывать приложения и их зависимости в **чарты (charts)**, которые могут быть легко установлены и управляемы в Kubernetes. В каждом чарте находятся манифесты Kubernetes, описывающие объекты, которые необходимы для развертывания приложения. Helm также позволяет управлять версиями чартов и обновлять их.

В Helm чарт представляет собой пакет, который содержит в себе все необходимое для установки и настройки приложения или сервиса в Kubernetes-кластере. Чарт может содержать в себе манифесты Kubernetes, настройки приложения и другие файлы.

**Темплейты (templates)** являются основной частью Helm-чарта и представляют собой файлы, которые содержат определенную структуру и помечены значками `{{}}`. Эти значки представляют переменные, которые будут заполнены при выполнении команды `helm install` или `helm upgrade`. Темплейты могут содержать манифесты Kubernetes и другие файлы, которые будут заполнены значениями переменных в процессе установки или обновления чарта.

Таким образом, чарт содержит все файлы и настройки приложения, а темплейты — это механизм для заполнения переменных внутри манифестов и других файлов в чарте.

Пример простого Helm-чарта для развертывания приложения Node.js на Kubernetes:

```
├── Chart.yaml          # Метаданные чарта
├── templates           # Шаблоны ресурсов Kubernetes
│   ├── deployment.yaml    # Шаблон развертывания Deployment
│   ├── service.yaml       # Шаблон создания сервиса Service
│   └── ingress.yaml       # Шаблон создания Ingress для доступа к приложению
└── values.yaml         # Значения по умолчанию для параметров чарта
```

`Chart.yaml` содержит метаданные чарта, такие как версия, имя, описание и зависимости:

```yaml
apiVersion: v2
name: my-node-app
description: A Helm chart for deploying a Node.js application
version: 0.1.0
appVersion: 1.0.0
dependencies:
  - name: mongodb
    version: 9.x.x
    repository: https://charts.bitnami.com/bitnami
```

`values.yaml` содержит значения по умолчанию для параметров чарта:

```yaml
# Количество реплик в Deployment
replicaCount: 1

# Образ Docker, используемый для приложения
image:
  repository: my-node-app
  tag: latest
  pullPolicy: IfNotPresent

# Порты, на которых работает приложение
service:
  name: my-node-app
  type: ClusterIP
  port: 3000

# Параметры Ingress
ingress:
  enabled: false
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
  path: /
  hosts:
    - my-node-app.example.com
```

Шаблоны ресурсов Kubernetes хранятся в директории `templates`. Например, `deployment.yaml` содержит шаблон развертывания *Deployment* для приложения Node.js:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-node-app.fullname" . }}
  labels:
    app: {{ include "my-node-app.name" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "my-node-app.name" . }}
  template:
    metadata:
      labels:
        app: {{ include "my-node-app.name" . }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 3000
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
```

`{{ .Values.replicaCount }}`, `{{ .Values.image.repository }}` и другие переменные в шаблонах заменяются на значения из `values.yaml`.

`service.yaml` содержит шаблон создания сервиса Service для доступа к приложению:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.service.name }}
```

**Kustomize** — это инструмент для настройки манифестов Kubernetes, который позволяет управлять параметрами конфигурации, такими как имя и порты, без необходимости изменения манифестов напрямую. Kustomize также позволяет управлять различными средами (dev, staging, prod) и автоматически генерировать манифесты на основе базовых шаблонов. Kustomize работает путем применения патчей к существующим манифестам, а не путем создания новых манифестов с нуля. Это делает процесс обновления конфигурации более безопасным и предотвращает возможные конфликты при слиянии изменений.

Ресурсы Kustomize — это объекты Kubernetes, такие как деплойменты, сервисы, конфигурационные карты и т. д., которые можно настроить или изменить с помощью Kustomize.

Таким образом, ресурсы Kustomize — это объекты Kubernetes, которые могут быть настроены и изменены с помощью Kustomize, чтобы предоставить гибкий и настраиваемый способ управления конфигурацией Kubernetes.