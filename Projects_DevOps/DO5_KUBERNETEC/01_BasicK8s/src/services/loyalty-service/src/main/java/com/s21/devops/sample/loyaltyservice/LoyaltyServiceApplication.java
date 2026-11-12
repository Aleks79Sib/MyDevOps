package com.s21.devops.sample.loyaltyservice;

// добавили импорт
import org.apache.commons.lang3.StringUtils;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class LoyaltyServiceApplication {

    // Перед сборкой образа мы не устанавливали здесь версию v3.do10_1.0 
    // сейчас напишем новую версию сборки v3.do10_1.0
    private static final String APP_VERSION = "v4.do10";
    public static void main(String[] args) {
        System.out.println(StringUtils.repeat("=", 20)
            + " loyalty-service " + APP_VERSION + " started "
            + StringUtils.repeat("=", 20));
        SpringApplication.run(LoyaltyServiceApplication.class, args);
    }

}
