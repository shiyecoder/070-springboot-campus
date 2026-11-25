package com.campus.market;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/** 校园超市线上订货与自提系统 启动类（NEW-070） */
@SpringBootApplication
@EnableScheduling
public class CampusMarketApplication {
    public static void main(String[] args) {
        SpringApplication.run(CampusMarketApplication.class, args);
    }
}
