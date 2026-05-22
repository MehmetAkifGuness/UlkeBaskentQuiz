package com.gunes.DunyaUlkeleri.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // STOMP endpoint
        // SockJS fallback: bazı ortamlarda (özellikle web) gerekli olabiliyor.
        registry.addEndpoint("/ws/conquest")
                .setAllowedOriginPatterns(CorsOriginPatterns.devAllowedOriginPatternsArray())
                .withSockJS();

        registry.addEndpoint("/ws/duel")
                .setAllowedOriginPatterns(CorsOriginPatterns.devAllowedOriginPatternsArray())
                .withSockJS();
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // Client -> Server: /app/...
        registry.setApplicationDestinationPrefixes("/app");

        // Server -> Client: /topic/...
        registry.enableSimpleBroker("/topic");

        // Gerekirse kullanıcı bazlı mesajlar için.
        // Gerekirse kullanıcı bazlı mesajlar için (/user/queue/...).
        registry.setUserDestinationPrefix("/user");
    }
}
