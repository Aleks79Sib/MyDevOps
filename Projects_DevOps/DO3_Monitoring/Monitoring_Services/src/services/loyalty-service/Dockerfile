# ============================================================
# Dockerfile для loyalty-service
# Порт: 8085 · БД: balances_db
# Полный аналог session-service
# ============================================================

FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /app

COPY pom.xml ./
RUN mvn dependency:go-offline -B

COPY src src
RUN mvn package -DskipTests -B

FROM eclipse-temurin:21-jdk-alpine AS runtime

# Устанавливаем bash (нужен для wait-for-it.sh)
RUN apk add --no-cache bash

WORKDIR /app

COPY --from=builder /app/target/*.jar ./app.jar

COPY wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod +x /usr/local/bin/wait-for-it.sh

EXPOSE 8085

CMD ["wait-for-it.sh", "-t", "60", "$POSTGRES_HOST:$POSTGRES_PORT", "--", "java", "-jar", "app.jar"]
