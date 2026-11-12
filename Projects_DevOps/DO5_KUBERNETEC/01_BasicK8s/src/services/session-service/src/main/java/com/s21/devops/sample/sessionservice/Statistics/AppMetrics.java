package com.s21.devops.sample.sessionservice.Statistics;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

/**
 * Собирает бизнес-метрики session-service через Micrometer.
 * Метрики автоматически становятся доступны на /actuator/prometheus
 */
@Component
public class AppMetrics {

    private final Counter authRequestsCounter;

    public AppMetrics(MeterRegistry registry) {
        this.authRequestsCounter = Counter.builder("auth_requests_total")
                .description("Количество запросов на авторизацию пользователей")
                .tag("service", "session-service")
                .register(registry);
    }

    public void incrementAuthRequests() {
        authRequestsCounter.increment();
    }
}
