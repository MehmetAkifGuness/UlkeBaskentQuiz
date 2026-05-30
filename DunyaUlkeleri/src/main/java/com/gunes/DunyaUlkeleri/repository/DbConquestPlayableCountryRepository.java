package com.gunes.DunyaUlkeleri.repository;

import java.io.InputStream;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

import org.springframework.context.annotation.Primary;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Repository;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gunes.DunyaUlkeleri.entity.PlayableCountryMeta;
import com.gunes.DunyaUlkeleri.entity.Question;

import lombok.RequiredArgsConstructor;

@Primary
@Repository
@RequiredArgsConstructor
public class DbConquestPlayableCountryRepository implements ConquestPlayableCountryRepository {

    private static final String ISO_TR_RESOURCE = "iso/i18n_iso_countries_tr.json";
    private static final String ISO_CODES_RESOURCE = "iso/i18n_iso_countries_codes.json";

    private final QuestionRepository questionRepository;
    private final ObjectMapper objectMapper;

    private volatile Cache cache;

    @Override
    public List<PlayableCountryMeta> findPlayableCountries(String continentFilter) {
        final Cache c = ensureCache();
        final String filter = normalizeContinentFilter(continentFilter);
        if ("ALL".equalsIgnoreCase(filter)) return c.all();
        return c.byContinent().getOrDefault(filter, List.of());
    }

    @Override
    public PlayableCountryMeta getMetaOrDefault(String isoCode, String defaultContinent) {
        final Cache c = ensureCache();
        final String key = normalizeUpper(isoCode);
        if (key == null || key.isBlank()) {
            return new PlayableCountryMeta(null, null, defaultContinent);
        }
        return c.byIso().getOrDefault(key, new PlayableCountryMeta(key, key, defaultContinent));
    }

    private Cache ensureCache() {
        Cache c = cache;
        if (c != null) return c;
        synchronized (this) {
            c = cache;
            if (c != null) return c;
            cache = c = loadCache();
            return c;
        }
    }

    private Cache loadCache() {
        final IsoLookup iso = loadIsoLookup();

        final Map<String, PlayableCountryMeta> byIso = new HashMap<>();
        final Map<String, List<PlayableCountryMeta>> byContinent = new HashMap<>();

        for (Question q : Optional.ofNullable(questionRepository.findAllByOrderByCountryNameAsc()).orElseGet(List::of)) {
            if (q == null) continue;
            final String name = safeTrim(q.getCountryName());
            if (name == null || name.isBlank()) continue;

            final String continent = toEnglishContinent(safeTrim(q.getContinent()));
            final String iso3 = iso.iso3OrNull(name);
            final String key = normalizeUpper(iso3 != null ? iso3 : name);
            if (key == null || key.isBlank()) continue;

            final PlayableCountryMeta meta = new PlayableCountryMeta(key, name, continent);
            byIso.putIfAbsent(meta.isoCode(), meta);
            byContinent.computeIfAbsent(meta.continent() == null ? "ALL" : meta.continent(), __ -> new ArrayList<>()).add(meta);
        }

        final List<PlayableCountryMeta> all = byIso.values().stream().filter(Objects::nonNull).toList();
        byContinent.putIfAbsent("ALL", all);

        return new Cache(all, byContinent, byIso);
    }

    private IsoLookup loadIsoLookup() {
        try (InputStream trIn = new ClassPathResource(ISO_TR_RESOURCE).getInputStream();
             InputStream codesIn = new ClassPathResource(ISO_CODES_RESOURCE).getInputStream()) {

            final JsonNode trRoot = objectMapper.readTree(trIn);
            final JsonNode countries = trRoot == null ? null : trRoot.get("countries");

            final Map<String, String> normalizedTrToAlpha2 = new HashMap<>();
            if (countries != null && countries.isObject()) {
                countries.fields().forEachRemaining(e -> {
                    final String alpha2 = normalizeUpper(e.getKey());
                    if (alpha2 == null || alpha2.isBlank()) return;
                    indexIsoName(normalizedTrToAlpha2, alpha2, e.getValue());
                });
            }

            final Map<String, String> alpha2ToAlpha3 = new HashMap<>();
            final List<List<Object>> codes = objectMapper.readValue(codesIn, new TypeReference<>() {});
            for (List<Object> row : Optional.ofNullable(codes).orElseGet(List::of)) {
                if (row == null || row.size() < 2) continue;
                final String a2 = normalizeUpper(String.valueOf(row.get(0)));
                final String a3 = normalizeUpper(String.valueOf(row.get(1)));
                if (a2 == null || a3 == null || a2.isBlank() || a3.isBlank()) continue;
                alpha2ToAlpha3.put(a2, a3);
            }

            return new IsoLookup(normalizedTrToAlpha2, alpha2ToAlpha3);
        } catch (Exception e) {
            return new IsoLookup(Map.of(), Map.of());
        }
    }

    private static void indexIsoName(Map<String, String> target, String alpha2, JsonNode value) {
        if (value == null) return;
        if (value.isTextual()) {
            indexIsoNameValue(target, alpha2, value.asText());
            return;
        }
        if (!value.isArray()) return;
        for (JsonNode n : value) {
            if (n != null && n.isTextual()) {
                indexIsoNameValue(target, alpha2, n.asText());
            }
        }
    }

    private static void indexIsoNameValue(Map<String, String> target, String alpha2, String name) {
        final String raw = safeTrim(name);
        if (raw == null || raw.isBlank()) return;
        indexValue(target, alpha2, raw);

        final String noParens = raw.replaceAll("\\([^)]*\\)", " ").trim();
        if (!noParens.isBlank() && !noParens.equals(raw)) {
            indexValue(target, alpha2, noParens);
        }
    }

    private static void indexValue(Map<String, String> target, String alpha2, String name) {
        final String key = normalizeName(name);
        if (key.isBlank()) return;
        target.putIfAbsent(key, alpha2);
    }

    private static String toEnglishContinent(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank() || "ALL".equalsIgnoreCase(v)) return "ALL";
        return switch (v) {
            case "Avrupa" -> "Europe";
            case "Asya" -> "Asia";
            case "Afrika" -> "Africa";
            case "Kuzey Amerika" -> "North America";
            case "Güney Amerika" -> "South America";
            case "Okyanusya" -> "Oceania";
            default -> v;
        };
    }

    private static String normalizeName(String value) {
        String v = safeTrim(value);
        if (v == null || v.isBlank()) return "";

        v = v.replace('İ', 'i').replace('I', 'i');
        v = v.toLowerCase(Locale.ROOT);
        v = v.replace('ç', 'c').replace('ğ', 'g').replace('ı', 'i').replace('ö', 'o').replace('ş', 's').replace('ü', 'u');
        v = Normalizer.normalize(v, Normalizer.Form.NFD).replaceAll("\\p{M}+", "");
        v = v.replaceAll("[^\\p{L}\\p{N}\\s]+", " ");
        v = v.replaceAll("\\s+", " ").trim();
        return v;
    }

    private static String normalizeUpper(String value) {
        final String v = safeTrim(value);
        return v == null ? null : v.toUpperCase(Locale.ROOT);
    }

    private static String normalizeContinentFilter(String value) {
        final String v = safeTrim(value);
        if (v == null || v.isBlank()) return "ALL";
        return v;
    }

    private static String safeTrim(String value) {
        return value == null ? null : value.trim();
    }

    private record Cache(
            List<PlayableCountryMeta> all,
            Map<String, List<PlayableCountryMeta>> byContinent,
            Map<String, PlayableCountryMeta> byIso
    ) {}

    private static final class IsoLookup {
        private final Map<String, String> normalizedTrToAlpha2;
        private final Map<String, String> alpha2ToAlpha3;

        private IsoLookup(Map<String, String> normalizedTrToAlpha2, Map<String, String> alpha2ToAlpha3) {
            this.normalizedTrToAlpha2 = normalizedTrToAlpha2;
            this.alpha2ToAlpha3 = alpha2ToAlpha3;
        }

        private String iso3OrNull(String turkishName) {
            final String key = normalizeName(turkishName);
            if (key.isBlank()) return null;
            final String alpha2 = normalizedTrToAlpha2.get(key);
            if (alpha2 == null || alpha2.isBlank()) return null;
            return alpha2ToAlpha3.get(normalizeUpper(alpha2));
        }
    }
}
