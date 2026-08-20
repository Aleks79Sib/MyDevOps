# ============================================================
# Dockerfile для gateway-service (фасад/шлюз)
# Описание: точка входа для внешних клиентов.
#           Маршрутизирует запросы к нужным микросервисам.
# Порт: 8087
# Особенность: НЕТ своей БД. Общается по HTTP с другими сервисами.
# ============================================================

# ---------- ЭТАП 1: СБОРКА (builder) ----------
FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /app

# Используем системный Maven (mvn) вместо Maven Wrapper (./mvnw)
# Образ maven:3.9-eclipse-temurin-21-alpine уже содержит Maven 3.9
COPY pom.xml ./
RUN mvn dependency:go-offline -B

COPY src src
RUN mvn package -DskipTests -B

# ---------- ЭТАП 2: ЗАПУСК (runtime) ----------
FROM eclipse-temurin:21-jdk-alpine AS runtime

# Устанавливаем bash (нужен для wait-for-it.sh)
RUN apk add --no-cache bash

WORKDIR /app

COPY --from=builder /app/target/*.jar ./app.jar

# Копируем wait-for-it.sh (на случай, если понадобится ждать другие сервисы)
COPY wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod +x /usr/local/bin/wait-for-it.sh

EXPOSE 8087

# Gateway не имеет своей БД, запускается сразу
CMD ["java", "-jar", "app.jar"]
