# 📘 Инструкция: Развёртывание Ollama на домашнем сервере

## 📋 Требования

**Железо:**
- CPU: AMD Ryzen 7 7700X (8 ядер / 16 потоков)
- RAM: 32 ГБ DDR5 6000 МГц
- SSD: Kingston KC3000 1TB NVMe
- GPU: отсутствует (CPU-only inference)

**ПО:**
- ОС: Ubuntu 26.04 LTS
- Docker Engine + Docker Compose v2

---

## 🐳 1. Конфигурация Docker Compose

Создайте файл `docker-compose.yml`:

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "11434:11434"
    environment:
      - OLLAMA_HOST=0.0.0.0
      - OLLAMA_KEEP_ALIVE=24h
      - OLLAMA_NUM_PARALLEL=2
      - OLLAMA_NO_GPU=1
      - OLLAMA_VULKAN=0
      - OLLAMA_MAX_LOADED_MODELS=3
      - OLLAMA_MAX_QUEUE=64
      - OLLAMA_ORIGINS=*
    networks:
      - hs_backend
    deploy:
      resources:
        limits:
          memory: 20G
          cpus: '10'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  ollama_data:
    driver: local

networks:
  hs_backend:
    external: true
```

### Запуск:
```bash
docker compose up -d ollama
docker compose logs -f ollama
```

Ожидается строка: `Listening on [::]:11434`

---

## 📦 2. Загрузка моделей

### Выбранный стек моделей

| Роль | Модель | RAM | Скорость | Языки |
| :--- | :--- | :--- | :--- | :--- |
| ⚡ Быстрая автоматизация | `lfm2.5:1.2b` | 1 ГБ | 70 т/с | EN |
| 💬 Быстрый чат | `gemma4:e4b` | 3-4 ГБ | 20-30 т/с | RU/SR/HR/EN |
| 🧠 Сложные задачи | `gemma4:12b` | 9-10 ГБ | 8-12 т/с | RU/SR/HR/EN + Vision |
| 🌐 Переводчик | `translategemma:4b` | 3-4 ГБ | 20-25 т/с | 55 языков |

### Команды загрузки

```bash
# Быстрая модель для автоматизации (прямой импорт с Hugging Face)
docker exec -it ollama ollama pull hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF

# Мультиязычная быстрая модель
docker exec -it ollama ollama pull gemma4:e4b

# Мощная модель для сложных задач (загружается по требованию)
docker exec -it ollama ollama pull gemma4:12b

# Специализированный переводчик
docker exec -it ollama ollama pull translategemma:4b
```

### Проверка установленных моделей:
```bash
docker exec -it ollama ollama list
```

---

## 🔒 3. Закрепление моделей в RAM

Благодаря `OLLAMA_MAX_LOADED_MODELS=3` в памяти будут постоянно 3 модели, четвёртая подгружается по требованию.

Закрепите основные модели через REST API (CLI-флаг `--keep-alive` **не поддерживается**):

```bash

curl -s http://localhost:11434/api/generate \
  -d '{"model":"lfm2.5:1.2b","keep_alive":-1}' > /dev/null

curl -s http://localhost:11434/api/generate \
  -d '{"model":"gemma4:e4b","keep_alive":-1}' > /dev/null

curl -s http://localhost:11434/api/generate \
  -d '{"model":"translategemma:4b","keep_alive":-1}' > /dev/null

# Открепить модели из памяти
curl -s http://localhost:11434/api/generate \
  -d '{"model":"gemma4:e4b","keep_alive":0}' > /dev/null
```

> 💡 `gemma4:12b` оставьте без закрепления — она будет подгружаться автоматически при обращении и выгружаться после использования.

[Docs Ollama](https://docs.ollama.com/faq#how-do-i-keep-a-model-loaded-in-memory-or-make-it-unload-immediately)

### Проверка загруженных в RAM моделей:
```bash
curl -s http://localhost:11434/api/ps | jq
```

`expires_at: "0001-01-01T00:00:00Z"` означает «никогда не выгружать».

---

## 🧪 4. Тестирование

### Быстрый тест (через CLI):
```bash
docker exec -it ollama ollama run gemma4:e4b "Привет!" --verbose
```

### Тест через OpenAI-совместимый API:
```bash
curl -X POST http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gemma4:e4b","messages":[{"role":"user","content":"Привет"}]}'
```

### Бенчмарк скорости:
```bash
docker exec -it ollama ollama run gemma4:e4b "Объясни Docker" --verbose
# Следить за строкой eval rate (токены/сек)
```

---

## 🔌 5. Интеграция с Nextcloud

### Настройки `integration_openai`:

```bash
docker exec -u www-data nextcloud php occ config:app:set integration_openai url --value="http://192.168.1.100:11434/v1"
docker exec -u www-data nextcloud php occ config:app:set integration_openai api_key --value="ollama"
docker exec -u www-data nextcloud php occ config:app:set integration_openai chat_model --value="gemma4:e4b"
docker exec -u www-data nextcloud php occ config:app:set integration_openai request_timeout --value="600"
```

### Настройка Task Processing воркера:

```bash
# Переключить режим background jobs
docker exec -u www-data nextcloud php occ background:cron
```

**На хосте (crontab):**
```cron
*/5 * * * * docker exec -u www-data nextcloud php -f /var/www/html/cron.php >/dev/null 2>&1
*/5 * * * * docker exec -u www-data nextcloud php occ taskprocessing:worker --timeout=240 --once >/dev/null 2>&1
```

---

## ⚠️ 6. Подтверждённые проблемы и решения

### Проблема 1: `Error: pull model manifest: file does not exist`

**Причина:** Неверный синтаксис имени модели. Квантование (например, `-q4_K_M`) в Ollama **не указывается** в теге.

**Решение:**
```bash
# ❌ Неправильно
docker exec -it ollama ollama pull lfm2.5:1.2b-instruct-q4_K_M

# ✅ Правильно
docker exec -it ollama ollama pull hf.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF
```

---

### Проблема 2: `missing tensor 'output_norm.weight'` для MoE моделей

**Причина:** Стабильная версия Ollama (v0.17.0) имеет баг с архитектурой `lfm2moe`. Это влияет на все MoE-модели (LFM2.5-8B-A1B, LFM2-24B-A2B).

**Решение:** Использовать образ `ollama/ollama:v0.17.1-rc0` или новее:
```yaml
services:
  ollama:
    image: ollama/ollama:v0.17.1-rc0
```

---

### Проблема 3: Флаг `--keep-alive` не работает в CLI

**Причина:** В `ollama run` нет флага `--keep-alive`. Это ошибка документации.

**Решение:** Использовать REST API:
```bash
curl -s http://localhost:11434/api/generate \
  -d '{"model":"gemma4:e4b","keep_alive":-1}' > /dev/null
```

---

### Проблема 4: Nextcloud Assistant — `DoesNotExistException` на ChattyLLM

**Симптом:**
```
SELECT ... FROM *PREFIX*assistant_chat_sns WHERE (id = ?) AND (user_id = ?)
Did expect one result but found none
```

**Причина:** Баг приложения `assistant` в NC 34 — слушатель не находит сессию чата при сохранении результата.

**Решение (подтверждено рабочее):**
1. Использовать **Free prompt** вместо ChattyLLM (обходит таблицу `assistant_chat_sns`)
2. Очистить старые задачи:
   ```bash
   docker exec -u www-data nextcloud php occ taskprocessing:task:cleanup
   ```

---

### Проблема 5: Задачи NC висят в `STATUS_SCHEDULED`

**Причина:** Нет активного Task Processing воркера. В NC 34 AI-задачи обрабатываются отдельным воркером `taskprocessing:worker`.

**Решение:**
```bash
# Ручной запуск для теста
docker exec -it -u www-data nextcloud php occ taskprocessing:worker --timeout=300 --verbose

# Постоянный запуск через cron (на хосте)
*/5 * * * * docker exec -u www-data nextcloud php occ taskprocessing:worker --timeout=240 --once >/dev/null 2>&1
```

---

### Проблема 6: Долгий ответ через Nextcloud (10-30 сек)

**Причины:**
- Модель выгружается из RAM между запросами
- Огромный system_prompt в ChattyLLM (~100 токенов overhead)
- UI NC использует polling вместо streaming

**Решение:**
1. Закрепить модели в RAM (см. пункт 3)
2. Использовать Free prompt вместо ChattyLLM
3. Для мгновенных ответов развернуть **Open WebUI** как отдельный интерфейс:
   ```yaml
   open-webui:
     image: ghcr.io/open-webui/open-webui:main
     environment:
       - OLLAMA_BASE_URL=http://ollama:11434
     ports:
       - "3000:8080"
   ```

---

### Проблема 7: LFM2.5 не поддерживает русский/сербский/хорватский

**Причина:** Официальный список языков LFM2.5: English, Arabic, Chinese, French, German, Japanese, Korean, Spanish.

**Решение:** Для RU/SR/HR использовать `gemma4:e4b`, `gemma4:12b` или `translategemma:4b`. LFM2.5 оставить только для англоязычной автоматизации.

---

### Проблема 8: ROCm/Vulkan ошибки при старте

**Причина:** На CPU-only системах Ollama пытается инициализировать GPU-стек.

**Решение:** Явно отключить в переменных окружения:
```yaml
environment:
  - OLLAMA_NO_GPU=1
  - OLLAMA_VULKAN=0
```

---

## 📊 Итоговый бюджет ресурсов

| Компонент | RAM | CPU |
| :--- | :--- | :--- |
| Ollama (3 активные модели) | ~8-10 ГБ | 10 потоков |
| **Резерв для 4-й модели** | 9-10 ГБ | (в рамках лимита) |
| **Свободно для системы** | ~12 ГБ | 6 потоков |

Стек готов к работе. Модели отвечают со скоростью:
- LFM2.5: **70 т/с**
- Gemma4 e4b: **16-30 т/с**
- Gemma4 12b: **7-12 т/с**
- TranslateGemma: **22 т/с**