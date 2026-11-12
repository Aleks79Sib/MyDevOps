package com.s21.devops.sample.reportservice.Statistics;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

/**
 * Собирает бизнес-метрики report-service через Micrometer.
 * Метрики автоматически становятся доступны на /actuator/prometheus
 */
@Component
public class AppMetrics {

    private final Counter rabbitMessagesProcessedCounter;

    public AppMetrics(MeterRegistry registry) {
        this.rabbitMessagesProcessedCounter = Counter.builder("rabbitmq_messages_processed_total")
                .description("Количество сообщений, обработанных из RabbitMQ")
                .tag("service", "report-service")
                .register(registry);
    }

    public void incrementRabbitMessagesProcessed() {
        rabbitMessagesProcessedCounter.increment();
    }
}
