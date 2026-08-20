# ============================================================
# Dockerfile для session-service
# Описание: сервис управления сессиями пользователей
# Порт: 8081
# Зависимости: PostgreSQL (БД: users_db)
#
# Используем Multi-stage build (многоэтапная сборка):
#   Stage 1 (builder) — СБОРКА приложения
#   Stage 2 (runtime) — ЗАПУСК приложения
#
# Проект написан на Java 8 (см. pom.xml), но запускаем на JDK 21
# (обратно совместим) — как рекомендовано в материалах проекта
# ============================================================

# ---------- ЭТАП 1: СБОРКА (builder) ----------
# maven:3.9-eclipse-temurin-21-alpine — свежий Maven 3.9 + JDK 21 на Alpine
# Alpine — минимальный Linux (~5MB), чтобы образ был лёгким
FROM maven:3.9-eclipse-temurin-21-alpine AS builder

# Рабочая директория
WORKDIR /app

# Копируем только файлы для загрузки зависимостей
# (оптимизация кэширования Docker)
# ВНИМАНИЕ: Используем системный Maven (mvn), а не Maven Wrapper (./mvnw),
# так как в образе maven:3.9-eclipse-temurin-21-alpine уже установлен Maven 3.9
# Maven Wrapper пытается скачать свою версию (3.8.1) и вызывает ошибку аргументов
COPY pom.xml ./

# Скачиваем все зависимости (кэшируемый слой)
RUN mvn dependency:go-offline -B

# Копируем исходный код
COPY src src

# Собираем .jar
RUN mvn package -DskipTests -B

# ---------- ЭТАП 2: ЗАПУСК (runtime) ----------
# openjdk:21-jdk-alpine — только среда выполнения Java 21 на Alpine
# (рекомендация из материалов проекта: materials/04-project_rus.md)
FROM eclipse-temurin:21-jdk-alpine AS runtime

# Устанавливаем bash (нужен для wait-for-it.sh, в Alpine нет bash по умолчанию)
RUN apk add --no-cache bash

WORKDIR /app

# Копируем .jar из этапа сборки
COPY --from=builder /app/target/*.jar ./app.jar

# Копируем скрипт ожидания готовности PostgreSQL
COPY wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod +x /usr/local/bin/wait-for-it.sh

# Информация о порте
EXPOSE 8081

# Запуск: ждём PostgreSQL → запускаем Java
CMD ["wait-for-it.sh", "-t", "60", "$POSTGRES_HOST:$POSTGRES_PORT", "--", "java", "-jar", "app.jar"]
