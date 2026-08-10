# 📊 Мониторинг системы (Glances)

---

## 1. Установка Glances

```bash
sudo apt install glances -y
```

---

## 2. Запуск мониторинга

```bash
# Запустить в tmux для постоянного мониторинга
tmux new -s monitor
glances
```

> Для выхода из tmux: `Ctrl+B, D`
> Для возврата: `tmux attach -t monitor`

---

## 3. Тестовая нагрузка

1. Создать 15 простых воркфлоу в n8n (парсинг RSS → Telegram)
2. Запустить все одновременно
3. Наблюдать в Glances:

| Показатель | Критерий успеха |
|------------|----------------|
| RAM | < 12 ГБ |
| CPU | < 80% |
| Jellyfin | без лагов |
| Dendrite | без лагов |

---

## 4. Полезные команды

```bash
# Запустить Glances в веб-режиме
glances -w

# Запустить с обновлением раз в 2 секунды
glances -t 2

# Экспорт в CSV
glances --export csv --export-csv-file ~/stats.csv

# Просмотр процессов
htop
btop
```
