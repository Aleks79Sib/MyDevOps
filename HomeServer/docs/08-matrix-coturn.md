# 💬 Matrix — мессенджер (Dendrite + Element + Coturn)

---

## 1. О сервисе

Для мессенджера используются:
- **Dendrite** — homeserver Matrix (лёгкий, Go)
- **Element Web** — веб-клиент для браузера
- **Coturn** — TURN-сервер для голосовых/видеозвонков

---

## 2. Настройка клиентов

Скачать приложение Element на телефоны:

👉 [https://element.io](https://element.io)

Настроить сервер в приложении: `https://chat.ваш-домен.com`

---

## 3. Coturn — TURN-сервер для звонков

Устанавливается на удалённом VPS (RSB) для звонков извне.

### 3.1. Создать конфиг на VPS

```bash
sudo mkdir -p /opt/coturn
sudo nano /opt/coturn/turnserver.conf
```

> Файл `turnserver.conf` содержит секретный ключ — выставить права `600`, владелец `root`.

```bash
sudo chmod 600 /opt/coturn/turnserver.conf
sudo chown root:root /opt/coturn/turnserver.conf
sudo chown root:root /opt/coturn
sudo chmod 700 /opt/coturn
```

### 3.2. Установить и запустить Coturn

```bash
sudo apt install coturn -y
sudo cp /opt/coturn/turnserver.conf /etc/turnserver.conf
sudo systemctl enable --now coturn
sudo systemctl status coturn
```

---

## 4. Обновление Dendrite на HS

```bash
# Путь к конфигу Dendrite на домашнем сервере
sudo nano /data/dendrite/dendrite.yaml
```

Обновить настройки для подключения Coturn.

---

## 5. Обновление Element Web

```bash
sudo nano ~/docker/server/element-config.json
```

---

## 6. Создание аккаунтов

После настройки сервера создать аккаунты для всех членов семьи через интерфейс Element или через регистрацию в Dendrite.
