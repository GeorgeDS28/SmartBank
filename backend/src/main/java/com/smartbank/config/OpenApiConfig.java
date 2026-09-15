//OpenApiConfig.java

package com.smartbank.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.security.SecurityRequirement;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI smartBankOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("SmartBank API")
                        .description("REST API documentation for SmartBank")
                        .version("1.0"))
                    .components(
                        new io.swagger.v3.oas.models.Components()
                                .addSecuritySchemes(
                                        "bearerAuth",
                                        new SecurityScheme()
                                                .type(SecurityScheme.Type.HTTP)
                                                .scheme("bearer")
                                                .bearerFormat("JWT")
                                )
                )
                .addSecurityItem(
                        new SecurityRequirement().addList("bearerAuth")
                );






    }
}