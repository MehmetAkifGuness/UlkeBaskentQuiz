package com.gunes.DunyaUlkeleri.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gunes.DunyaUlkeleri.exception.ApiErrorResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;
    private final ObjectMapper objectMapper;

    // SİLDİĞİMİZ SINIFIN GÖREVİNİ ARTIK BU METOT YAPIYOR
    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(cors -> cors.configurationSource(request -> {
                var corsConfiguration = new org.springframework.web.cors.CorsConfiguration();
                
                // Dev ortamı için esnek ama kontrollü origin izinleri.
                // Not: Mobil uygulamalarda CORS uygulanmaz; burada özellikle web istemcileri hedeflenir.
                corsConfiguration.setAllowedOriginPatterns(java.util.List.of(
                    "http://localhost:*",
                    "http://127.0.0.1:*",
                    "http://10.0.2.2:*"
                ));
                
                corsConfiguration.setAllowedMethods(java.util.List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
                corsConfiguration.setAllowedHeaders(java.util.List.of("*"));
                return corsConfiguration;
            }))
            // 🚨 MİMARİ YAMA: Spring Security'nin HTML hata atmasını engelleyip, temiz JSON döndürmesini sağladık
            .exceptionHandling(exception -> exception
                .authenticationEntryPoint((request, response, authException) -> {
                    response.setContentType("application/json;charset=UTF-8");
                    response.setStatus(HttpStatus.UNAUTHORIZED.value());
                    objectMapper.writeValue(
                            response.getWriter(),
                            ApiErrorResponse.of(
                                    HttpStatus.UNAUTHORIZED,
                                    "UNAUTHORIZED",
                                    "Oturum süresi doldu veya yetkisiz erişim.",
                                    request.getRequestURI(),
                                    null
                            )
                    );
                })
                .accessDeniedHandler((request, response, accessDeniedException) -> {
                    response.setContentType("application/json;charset=UTF-8");
                    response.setStatus(HttpStatus.FORBIDDEN.value());
                    objectMapper.writeValue(
                            response.getWriter(),
                            ApiErrorResponse.of(
                                    HttpStatus.FORBIDDEN,
                                    "FORBIDDEN",
                                    "Bu işlem için yetkiniz yok.",
                                    request.getRequestURI(),
                                    null
                            )
                    );
                })
            )
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/error").permitAll()
                // ADIM 5: Conquest multiplayer altyapısı (şimdilik auth zorunlu değil).
                .requestMatchers("/api/conquest/**", "/ws/conquest/**").permitAll()
                .requestMatchers("/api/game/**").authenticated()
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
