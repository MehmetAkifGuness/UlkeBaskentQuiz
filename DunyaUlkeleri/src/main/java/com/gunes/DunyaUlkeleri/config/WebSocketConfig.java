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
                .setAllowedOriginPatterns(
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
                        "https://172.31.*:*",
                        "http://localhost:3000",
                        "http://localhost:5000",
                        "http://localhost:8080"
                )
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
