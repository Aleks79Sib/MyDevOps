Да. Давай сделаем **два полноценных плана**, причём оба начинаются с уже выполненного тобой пункта 4 — `ingress-nginx` у тебя работает на `80:32512` и `443:31152`.

Пункт 5 требует `cert-manager` и wildcard-сертификат, а пункт 6 — Ingress с доменом и этим сертификатом. 

Я бы **сначала попробовал План 1**: он полностью локальный, ничего покупать не надо. Если преподавателю принципиально нужен реальный домен/публичный сертификат, тогда переходим к Плану 2.

---

# Общая подготовка

У тебя сейчас:

```text
master-1   10.181.19.242
worker-1   10.181.19.249
worker-2   10.181.19.241
```

Nginx:

```text
HTTP   NodePort 32512
HTTPS  NodePort 31152
```

Проверка:

```bash
multipass exec master-1 -- sudo k3s kubectl get pods -n ingress-nginx
```

Должно быть:

```text
ingress-nginx-controller-...   1/1   Running
```

Это уже есть.

---

# 🟢 ПЛАН 1 — полностью локальный

## Что получаем

Будем использовать вымышленный локальный домен:

```text
k8s.local
```

Wildcard:

```text
*.k8s.local
```

Например, приложение потом будет доступно как:

```text
app.k8s.local
```

Схема:

```text
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

Это соответствует идее `cert-manager` из учебного материала: автоматическое управление TLS-сертификатами Kubernetes и интеграция с Ingress. 

---

## Шаг 1. Установить cert-manager

На `master-1`:

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
```

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get pods -n cert-manager
```

Ждём:

```text
cert-manager             1/1   Running
cert-manager-cainjector  1/1   Running
cert-manager-webhook     1/1   Running
```

Пока они не `Running`, дальше не идём.

---

# Шаг 2. Создать SelfSigned ClusterIssuer

Создадим файл:

```text
src/cert-manager-selfsigned.yaml
```

Содержимое:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
```

Применяем:

```bash
multipass transfer src/cert-manager-selfsigned.yaml master-1:
```

А затем:

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/cert-manager-selfsigned.yaml
```

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get clusterissuer
```

Ожидаем:

```text
NAME                READY   AGE
selfsigned-issuer   True    ...
```

---

# Шаг 3. Создать Root CA Certificate

Теперь cert-manager сам создаст наш корневой CA.

Создаём:

```text
src/root-ca.yaml
```

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: root-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: k8s-local-root-ca
  secretName: root-ca-secret
  duration: 87600h
  renewBefore: 720h
  privateKey:
    algorithm: RSA
    size: 4096
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
```

Применяем:

```bash
multipass transfer src/root-ca.yaml master-1:
```

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/root-ca.yaml
```

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get certificate -n cert-manager
```

Должно быть примерно:

```text
NAME      READY   SECRET           AGE
root-ca   True    root-ca-secret   ...
```

И:

```bash
multipass exec master-1 -- sudo k3s kubectl get secret -n cert-manager
```

Должен появиться:

```text
root-ca-secret
```

---

# Шаг 4. Создать CA ClusterIssuer

Теперь `root-ca-secret` будет использоваться как наш локальный центр сертификации.

Создаём:

```text
src/ca-issuer.yaml
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
multipass transfer src/ca-issuer.yaml master-1:
```

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/ca-issuer.yaml
```

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get clusterissuer
```

Должно быть:

```text
NAME                READY
selfsigned-issuer   True
ca-issuer           True
```

---

# Шаг 5. Создать wildcard Certificate

Теперь самое интересное.

Создаём:

```text
src/wildcard-certificate.yaml
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
multipass transfer src/wildcard-certificate.yaml master-1:
```

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/wildcard-certificate.yaml
```

---

# Шаг 6. Проверить wildcard-сертификат

```bash
multipass exec master-1 -- sudo k3s kubectl get certificate
```

Нужно получить:

```text
NAME                 READY   SECRET                    AGE
wildcard-k8s-local   True    wildcard-k8s-local-tls    ...
```

Очень важная проверка:

```bash
multipass exec master-1 -- sudo k3s kubectl describe certificate wildcard-k8s-local
```

И:

```bash
multipass exec master-1 -- sudo k3s kubectl get secret wildcard-k8s-local-tls
```

Если:

```text
READY=True
```

— **пункт 5 фактически выполнен**.

---

# Шаг 7. Использовать Secret в Ingress

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

Но сам TLS будет готов уже сейчас.

---

# Шаг 8. Настроить локальное имя

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

можно отдельно настроить проброс `443 → 31152`.

---

# 🔵 ПЛАН 2 — настоящий домен + Cloudflare + Let's Encrypt

Теперь второй вариант.

Ты предложил домен:

```text
iavne.niw
```

Если это **реально зарегистрированный домен**, которым ты управляешь через Cloudflare, тогда этот вариант значительно интереснее.

Если это просто придуманное имя — Let's Encrypt его не выдаст.

Здесь схема будет:

```text
                     Cloudflare DNS
                          │
                          │ DNS-01
                          ▼
                    Let's Encrypt
                          │
                          ▼
                     cert-manager
                          │
                          ▼
                 *.iavne.niw
                          │
                          ▼
               Kubernetes Secret
                          │
                          ▼
                  Nginx Ingress
```

Для wildcard нужен именно DNS-01 challenge.

---

# Шаг 1. cert-manager

Если уже сделал План 1, **повторно устанавливать cert-manager не нужно**.

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get pods -n cert-manager
```

Если:

```text
cert-manager             1/1 Running
cert-manager-cainjector  1/1 Running
cert-manager-webhook     1/1 Running
```

переходим дальше.

---

# Шаг 2. Создать API Token в Cloudflare

В Cloudflare создаёшь API Token с правом:

```text
Zone
  DNS
    Edit
```

и ограничиваешь его конкретной зоной:

```text
iavne.niw
```

**Не надо использовать глобальный Cloudflare API Key**, если можно создать ограниченный API Token.

Получишь значение вида:

```text
CLOUDFLARE_API_TOKEN=xxxxxxxxxxxxxxxx
```

---

# Шаг 3. Создать Kubernetes Secret

Создаём Secret:

```bash
multipass exec master-1 -- sudo k3s kubectl create secret generic cloudflare-api-token-secret \
  --namespace cert-manager \
  --from-literal=api-token='ТВОЙ_CLOUDFLARE_API_TOKEN'
```

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get secret -n cert-manager
```

Должен появиться:

```text
cloudflare-api-token-secret
```

---

# Шаг 4. Создать ClusterIssuer Let's Encrypt

Создаём:

```text
src/letsencrypt-cloudflare.yaml
```

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: ТВОЙ_EMAIL
    server: https://acme-v02.api.letsencrypt.org/directory

    privateKeySecretRef:
      name: letsencrypt-prod-account-key

    solvers:
      - dns01:
          cloudflare:
            apiTokenSecretRef:
              name: cloudflare-api-token-secret
              key: api-token
```

Применяем:

```bash
multipass transfer src/letsencrypt-cloudflare.yaml master-1:
```

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/letsencrypt-cloudflare.yaml
```

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get clusterissuer
```

Ожидаем:

```text
NAME               READY
letsencrypt-prod   True
```

---

# Шаг 5. Создать настоящий wildcard Certificate

Создаём:

```text
src/wildcard-iavne-niw.yaml
```

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-iavne-niw
  namespace: default
spec:
  secretName: wildcard-iavne-niw-tls

  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
    group: cert-manager.io

  commonName: "*.iavne.niw"

  dnsNames:
    - "*.iavne.niw"
    - "iavne.niw"

  duration: 2160h
  renewBefore: 360h
```

Применяем:

```bash
multipass transfer src/wildcard-iavne-niw.yaml master-1:
```

```bash
multipass exec master-1 -- sudo k3s kubectl apply \
  -f /home/ubuntu/wildcard-iavne-niw.yaml
```

---

# Шаг 6. Следим за получением сертификата

```bash
multipass exec master-1 -- sudo k3s kubectl get certificate
```

Сначала можешь увидеть:

```text
NAME                 READY   SECRET                   AGE
wildcard-iavne-niw   False   wildcard-iavne-niw-tls   20s
```

Это нормально.

Смотрим:

```bash
multipass exec master-1 -- sudo k3s kubectl describe certificate wildcard-iavne-niw
```

И:

```bash
multipass exec master-1 -- sudo k3s kubectl get certificaterequest
```

И:

```bash
multipass exec master-1 -- sudo k3s kubectl get challenge
```

Если DNS настроен правильно, в итоге:

```text
wildcard-iavne-niw   True
```

---

# Шаг 7. Проверяем Secret

```bash
multipass exec master-1 -- sudo k3s kubectl get secret wildcard-iavne-niw-tls
```

Получим примерно:

```text
NAME                    TYPE                DATA
wildcard-iavne-niw-tls  kubernetes.io/tls   2
```

Вот теперь у нас настоящий сертификат Let's Encrypt:

```text
*.iavne.niw
```

---

# Шаг 8. Ingress

Когда появится твой Service приложения, например:

```text
my-app
```

создаём:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  ingressClassName: nginx

  tls:
    - hosts:
        - app.iavne.niw
      secretName: wildcard-iavne-niw-tls

  rules:
    - host: app.iavne.niw
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

И:

```bash
multipass exec master-1 -- sudo k3s kubectl apply -f ingress.yaml
```

Проверяем:

```bash
multipass exec master-1 -- sudo k3s kubectl get ingress
```

---

# Что выбрать?

Я бы для твоей работы сделал так:

|                              | План 1 | План 2                        |
| ---------------------------- | ------ | ----------------------------- |
| Покупать домен               | ❌      | возможно, если домен уже есть |
| Cloudflare                   | ❌      | ✅                             |
| Let's Encrypt                | ❌      | ✅                             |
| cert-manager                 | ✅      | ✅                             |
| Wildcard                     | ✅      | ✅                             |
| HTTPS                        | ✅      | ✅                             |
| Браузер доверяет сертификату | ❌      | ✅                             |
| Работает полностью локально  | ✅      | ❌                             |
| Нужен внешний DNS            | ❌      | ✅                             |
| Хорош для учебного стенда    | **✅**  | **✅✅**                        |

### Моя рекомендация

**Сначала План 1.**

Он позволит тебе спокойно выполнить и проверить:

```text
Nginx
 ↓
cert-manager
 ↓
SelfSigned
 ↓
Root CA
 ↓
CA Issuer
 ↓
Wildcard Certificate
 ↓
TLS Secret
```

Если всё заработает — у тебя уже практически закрыт пункт 5.

А если преподаватель скажет **«нет, нужен именно настоящий домен и сертификат Let's Encrypt»**, тогда переключаемся на План 2 и делаем Cloudflare DNS-01.

---

### Но есть один важный момент по `iavne.niw`

Если `iavne.niw` — это **реально зарегистрированный домен**, напиши мне, что он уже добавлен в Cloudflare. Если это просто пример, то во втором плане надо заменить его на настоящий домен.

И ещё: **я бы не создавал сейчас Ingress из обоих планов**. Сначала сделай только установку `cert-manager` и получение сертификата. Сам Ingress логичнее закончить после появления Service приложения на пунктах 7–8, потому что сейчас у нас ещё нет backend-сервиса. Это позволит не получить искусственную ошибку `service "..." not found`.

