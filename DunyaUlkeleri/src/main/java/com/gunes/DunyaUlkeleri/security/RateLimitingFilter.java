package com.gunes.DunyaUlkeleri.security;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gunes.DunyaUlkeleri.util.exception.ApiErrorResponse;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class RateLimitingFilter extends OncePerRequestFilter {

    private static final Rule AVATAR_UPLOAD_RULE = new Rule(
            "avatar_upload",
            5,
            5,
            Duration.ofMinutes(1)
    );

    private static final Rule FORGOT_PASSWORD_RULE = new Rule(
            "forgot_password",
            3,
            3,
            Duration.ofMinutes(10)
    );

    private static final Rule RESEND_VERIFICATION_RULE = new Rule(
            "resend_verification",
            3,
            3,
            Duration.ofMinutes(10)
    );

    private static final long BUCKET_TTL_NANOS = Duration.ofMinutes(30).toNanos();
    private static final long CLEANUP_INTERVAL_NANOS = Duration.ofMinutes(10).toNanos();

    private final ObjectMapper objectMapper;

    private final Map<String, TokenBucket> buckets = new ConcurrentHashMap<>();
    private final AtomicLong lastCleanupNanos = new AtomicLong(System.nanoTime());

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        Rule rule = resolveRule(request);
        if (rule == null) {
            filterChain.doFilter(request, response);
            return;
        }

        long nowNanos = System.nanoTime();
        String bucketKey = rule.id() + ":" + resolveIdentityKey(request);
        TokenBucket bucket = buckets.computeIfAbsent(
                bucketKey,
                ignored -> new TokenBucket(rule.capacity(), rule.refillTokens(), rule.refillPeriod())
        );

        TokenBucket.ConsumeResult consumeResult = bucket.tryConsume(nowNanos, 1);
        tryCleanup(nowNanos);

        if (consumeResult.allowed()) {
            filterChain.doFilter(request, response);
            return;
        }

        int retryAfterSeconds = Math.max(1, (int) Math.ceil(consumeResult.retryAfter().toSeconds()));
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setContentType("application/json;charset=UTF-8");
        response.setHeader("Retry-After", String.valueOf(retryAfterSeconds));
        objectMapper.writeValue(
                response.getWriter(),
                ApiErrorResponse.of(
                        HttpStatus.TOO_MANY_REQUESTS,
                        "RATE_LIMIT_EXCEEDED",
                        "Çok fazla istek attınız. Lütfen daha sonra tekrar deneyin.",
                        request.getRequestURI(),
                        Map.of(
                                "rule", rule.id(),
                                "retryAfterSeconds", retryAfterSeconds
                        )
                )
        );
    }

    private static Rule resolveRule(HttpServletRequest request) {
        String method = request.getMethod();
        String path = request.getRequestURI();

        if ("POST".equalsIgnoreCase(method) && "/api/user/avatar/upload".equals(path)) {
            return AVATAR_UPLOAD_RULE;
        }
        if ("POST".equalsIgnoreCase(method) && "/api/auth/forgot-password".equals(path)) {
            return FORGOT_PASSWORD_RULE;
        }
        if ("POST".equalsIgnoreCase(method) && "/api/auth/resend-verification".equals(path)) {
            return RESEND_VERIFICATION_RULE;
        }
        return null;
    }

    private static String resolveIdentityKey(HttpServletRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null
                && authentication.isAuthenticated()
                && !(authentication instanceof AnonymousAuthenticationToken)) {
            return "user:" + authentication.getName();
        }
        return "ip:" + request.getRemoteAddr();
    }

    private void tryCleanup(long nowNanos) {
        long previous = lastCleanupNanos.get();
        if (nowNanos - previous < CLEANUP_INTERVAL_NANOS) {
            return;
        }
        if (!lastCleanupNanos.compareAndSet(previous, nowNanos)) {
            return;
        }

        buckets.entrySet().removeIf(entry -> entry.getValue().isExpired(nowNanos, BUCKET_TTL_NANOS));
    }

    private record Rule(String id, int capacity, int refillTokens, Duration refillPeriod) {}

    private static final class TokenBucket {
        private final long capacity;
        private final long refillTokens;
        private final long refillPeriodNanos;

        private double tokens;
        private long lastRefillNanos;
        private volatile long lastSeenNanos;

        private TokenBucket(long capacity, long refillTokens, Duration refillPeriod) {
            this.capacity = Math.max(1, capacity);
            this.refillTokens = Math.max(1, refillTokens);
            this.refillPeriodNanos = Math.max(1, refillPeriod.toNanos());

            long now = System.nanoTime();
            this.tokens = this.capacity;
            this.lastRefillNanos = now;
            this.lastSeenNanos = now;
        }

        private synchronized ConsumeResult tryConsume(long nowNanos, long cost) {
            lastSeenNanos = nowNanos;
            refill(nowNanos);

            if (tokens >= cost) {
                tokens -= cost;
                return ConsumeResult.permit();
            }

            double missing = cost - tokens;
            double tokensPerNano = (double) refillTokens / (double) refillPeriodNanos;
            long waitNanos = (long) Math.ceil(missing / tokensPerNano);
            return ConsumeResult.reject(Duration.ofNanos(waitNanos));
        }

        private void refill(long nowNanos) {
            long elapsed = nowNanos - lastRefillNanos;
            if (elapsed <= 0) {
                return;
            }

            double tokensToAdd = ((double) elapsed * (double) refillTokens) / (double) refillPeriodNanos;
            if (tokensToAdd <= 0) {
                return;
            }

            tokens = Math.min(capacity, tokens + tokensToAdd);
            lastRefillNanos = nowNanos;
        }

        private boolean isExpired(long nowNanos, long ttlNanos) {
            return nowNanos - lastSeenNanos > ttlNanos;
        }

        private record ConsumeResult(boolean allowed, Duration retryAfter) {
            private static ConsumeResult permit() {
                return new ConsumeResult(true, Duration.ZERO);
            }

            private static ConsumeResult reject(Duration retryAfter) {
                return new ConsumeResult(false, retryAfter);
            }
        }
    }
}
