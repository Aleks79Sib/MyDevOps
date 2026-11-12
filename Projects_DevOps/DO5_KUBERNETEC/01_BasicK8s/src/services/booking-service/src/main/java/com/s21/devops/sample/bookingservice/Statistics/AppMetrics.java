package com.s21.devops.sample.bookingservice.Statistics;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

/**
 * Собирает бизнес-метрики booking-service через Micrometer.
 * Метрики автоматически становятся доступны на /actuator/prometheus
 */
@Component
public class AppMetrics {

    private final Counter rabbitMessagesSentCounter;
    private final Counter bookingsCreatedCounter;

    public AppMetrics(MeterRegistry registry) {
        this.rabbitMessagesSentCounter = Counter.builder("rabbitmq_messages_sent_total")
                .description("Количество сообщений, отправленных в RabbitMQ")
                .tag("service", "booking-service")
                .register(registry);

        this.bookingsCreatedCounter = Counter.builder("bookings_created_total")
                .description("Количество созданных бронирований")
                .tag("service", "booking-service")
                .register(registry);
    }

    public void incrementRabbitMessagesSent() {
        rabbitMessagesSentCounter.increment();
    }

    public void incrementBookingsCreated() {
        bookingsCreatedCounter.increment();
    }
}
