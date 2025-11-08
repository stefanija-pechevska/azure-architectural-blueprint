package com.csom.platform.orderservice.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Value("${server.port:8080}")
    private String serverPort;

    @Bean
    public OpenAPI orderServiceOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Order Service API")
                .description("REST API for order management. All endpoints are exposed via Apigee API Gateway.")
                .version("v1.0")
                .contact(new Contact()
                    .name("CSOM Platform Team")
                    .email("api-support@company.com"))
                .license(new License()
                    .name("Proprietary")
                    .url("https://company.com/license")))
            .servers(List.of(
                new Server()
                    .url("http://localhost:" + serverPort)
                    .description("Local Development Server"),
                new Server()
                    .url("https://apigee.example.com/external-api")
                    .description("External API Proxy (Apigee)"),
                new Server()
                    .url("https://apigee.example.com/internal-api")
                    .description("Internal API Proxy (Apigee)")
            ));
    }
}

