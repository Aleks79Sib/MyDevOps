# ============================================================
# Dockerfile для booking-service
# Порт: 8083
# Зависимости: PostgreSQL (reservations_db)
#              RabbitMQ (очередь сообщений)
#              HTTP-сервисы: hotel, payment, loyalty
#
# Отличие от session-service: нужно ждать НЕ ТОЛЬКО PostgreSQL,
# но и RabbitMQ (тоже по TCP). HTTP-сервисы ждать не нужно —
# они поднимутся позже, а booking обработает ошибки подключения.
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
# RUN apk add --no-cache bash curl

WORKDIR /app

COPY --from=builder /app/target/*.jar ./app.jar

COPY wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod +x /usr/local/bin/wait-for-it.sh

EXPOSE 8083

# Ждём И PostgreSQL, И RabbitMQ (цепочка из двух wait-for-it)
# RabbitMQ слушает порт 5672 (AMQP)
CMD ["sh", "-c", "\
  wait-for-it.sh -t 60 $POSTGRES_HOST:$POSTGRES_PORT -- \
  wait-for-it.sh -t 60 $RABBIT_MQ_HOST:$RABBIT_MQ_PORT -- \
  java -jar app.jar"]
