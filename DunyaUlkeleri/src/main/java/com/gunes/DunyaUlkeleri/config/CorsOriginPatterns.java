package com.gunes.DunyaUlkeleri.config;

import java.util.List;

public final class CorsOriginPatterns {

    private CorsOriginPatterns() {
    }

    /**
     * Dev ortamı için esnek ama kontrollü origin izinleri.
     *
     * <p>Not: Mobil uygulamalarda CORS uygulanmaz; burada özellikle web istemcileri hedeflenir.</p>
     */
    public static final List<String> DEV_ALLOWED_ORIGIN_PATTERNS = List.of(
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
    );

    public static String[] devAllowedOriginPatternsArray() {
        return DEV_ALLOWED_ORIGIN_PATTERNS.toArray(String[]::new);
    }
}

