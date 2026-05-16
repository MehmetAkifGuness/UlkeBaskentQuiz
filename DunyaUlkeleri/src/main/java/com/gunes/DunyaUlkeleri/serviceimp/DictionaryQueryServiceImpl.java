package com.gunes.DunyaUlkeleri.serviceimp;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gunes.DunyaUlkeleri.dto.response.DictionaryResponse;
import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.repository.QuestionRepository;
import com.gunes.DunyaUlkeleri.service.DictionaryQueryService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DictionaryQueryServiceImpl implements DictionaryQueryService {

    private static final Duration CACHE_TTL = Duration.ofMinutes(10);

    private volatile DictionaryCache cache;

    private final QuestionRepository questionRepository;

    @Override
    public List<DictionaryResponse> getDictionary() {
        final Instant now = Instant.now();
        final DictionaryCache currentCache = cache;

        if (currentCache != null && isCacheValid(currentCache, now)) {
            return currentCache.data;
        }

        synchronized (this) {
            final Instant nowLocked = Instant.now();
            final DictionaryCache lockedCache = cache;
            if (lockedCache != null && isCacheValid(lockedCache, nowLocked)) {
                return lockedCache.data;
            }

            final List<Question> allQuestions =
                    questionRepository.findAllByOrderByCountryNameAsc();
            final List<DictionaryResponse> fresh = allQuestions.stream()
                    .map(q -> new DictionaryResponse(
                            q.getCountryName(),
                            q.getCapitalName(),
                            q.getContinent()
                    ))
                    .toList();

            final List<DictionaryResponse> immutableFresh = List.copyOf(fresh);
            cache = new DictionaryCache(nowLocked, immutableFresh);
            return immutableFresh;
        }
    }

    private static boolean isCacheValid(DictionaryCache cache, Instant now) {
        return Duration.between(cache.createdAt, now).compareTo(CACHE_TTL) < 0;
    }

    private static final class DictionaryCache {
        private final Instant createdAt;
        private final List<DictionaryResponse> data;

        private DictionaryCache(Instant createdAt, List<DictionaryResponse> data) {
            this.createdAt = createdAt;
            this.data = data;
        }
    }
}
