package com.s21.devops.sample.gatewayservice.Statistics;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Считает КАЖДЫЙ запрос, дошедший до gateway-service (/api/v1/gateway/**).
 * Регистрируется Spring Boot автоматически, т.к. это Filter-бин.
 */
@Component
public class GatewayMetricsFilter extends OncePerRequestFilter {

    private final Counter gatewayRequestsCounter;

    public GatewayMetricsFilter(MeterRegistry registry) {
        this.gatewayRequestsCounter = Counter.builder("gateway_requests_total")
                .description("Количество запросов, полученных на gateway")
                .tag("service", "gateway-service")
                .register(registry);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if (request.getRequestURI().startsWith("/api/v1/gateway")) {
            gatewayRequestsCounter.increment();
        }
        filterChain.doFilter(request, response);
    }
}
