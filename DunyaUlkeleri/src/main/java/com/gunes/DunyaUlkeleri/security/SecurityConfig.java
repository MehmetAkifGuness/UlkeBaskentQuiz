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
                    "http://10.0.2.2:*",
                    "http://10.*:*",
                    "http://192.168.*:*",
                    "http://172.16.*:*",
                    "http://172.17.*:*",
                    "http://172.18.*:*",
                    "http://172.19.*:*",
                    "http://172.20.*:*",
                    "http://172.21.*:*",
                    "http://172.22.*:*",
                    "http://172.23.*:*",
                    "http://172.24.*:*",
                    "http://172.25.*:*",
                    "http://172.26.*:*",
                    "http://172.27.*:*",
                    "http://172.28.*:*",
                    "http://172.29.*:*",
                    "http://172.30.*:*",
                    "http://172.31.*:*",
                    "https://localhost:*",
                    "https://127.0.0.1:*",
                    "https://10.0.2.2:*",
                    "https://10.*:*",
                    "https://192.168.*:*",
                    "https://172.16.*:*",
                    "https://172.17.*:*",
                    "https://172.18.*:*",
                    "https://172.19.*:*",
                    "https://172.20.*:*",
                    "https://172.21.*:*",
                    "https://172.22.*:*",
                    "https://172.23.*:*",
                    "https://172.24.*:*",
                    "https://172.25.*:*",
                    "https://172.26.*:*",
                    "https://172.27.*:*",
                    "https://172.28.*:*",
                    "https://172.29.*:*",
                    "https://172.30.*:*",
                    "https://172.31.*:*"
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
