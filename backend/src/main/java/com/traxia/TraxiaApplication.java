package com.traxia;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class TraxiaApplication {

    public static void main(String[] args) {
        SpringApplication.run(TraxiaApplication.class, args);
    }
}
