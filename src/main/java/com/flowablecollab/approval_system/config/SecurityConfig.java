package com.flowablecollab.approval_system.config;

import com.flowablecollab.approval_system.security.JwtAuthenticationFilter;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.util.Map;

@Configuration
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final ObjectMapper objectMapper;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint((request, response, authException) -> {
                            response.setStatus(401);
                            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                            response.getWriter().write(objectMapper.writeValueAsString(Map.of(
                                    "error", "Unauthorized"
                            )));
                        })
                        .accessDeniedHandler((request, response, accessDeniedException) -> {
                            response.setStatus(403);
                            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                            response.getWriter().write(objectMapper.writeValueAsString(Map.of(
                                    "error", "Forbidden"
                            )));
                        }))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/",
                                "/index.html",
                                "/login.html",
                                "/admin-register.html",
                                "/login",
                                "/error"
                        ).permitAll()
                        .requestMatchers("/api/auth/bootstrap-status", "/api/auth/bootstrap", "/api/auth/login", "/api/auth/login/2fa",
                                "/api/auth/2fa/recovery/validate").permitAll()
                        .requestMatchers("/api/admin/**").hasAnyRole("ADMIN", "SYS_ADMIN")
                        .requestMatchers("/api/rbac/**").hasAnyRole("ADMIN", "SYS_ADMIN")
                        .requestMatchers(HttpMethod.POST,
                                "/api/forms/definitions",
                                "/api/forms/versions",
                                "/api/forms/fields").hasRole("DESIGNER")
                        .requestMatchers(HttpMethod.POST,
                                "/api/forms/instances",
                                "/api/forms/validate").hasRole("EMPLOYEE")
                        .requestMatchers(HttpMethod.POST, "/api/workflow/requests").hasRole("EMPLOYEE")
                        .requestMatchers("/api/auth/2fa/**").authenticated()
                        .requestMatchers("/api/auth/me").authenticated()
                        .anyRequest().authenticated())
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
