import 'dart:convert';

import 'package:flutter/services.dart';

/// ISO kodları ile ülke adı (TR) arasında çeviri/eşleştirme servisi.
///
/// Amaç:
/// - Backend sözlüğünde gelen ülke adları çoğunlukla Türkçe.
/// - Harita (GeoJSON) tarafında ise ISO Alpha-3 gibi kodlar bulunuyor.
/// - Bu servis, TR ülke adını ISO3'e çevirmek için küçük bir offline tablo kullanır.
///
/// Kullanılan veri:
/// - `assets/iso/i18n_iso_countries_tr.json`  (alpha-2 -> TR isim/alias)
/// - `assets/iso/i18n_iso_countries_codes.json` (alpha-2 <-> alpha-3 dönüşümü)
///
/// Not: Bu tablo, i18n-iso-countries paketinin veri dosyalarından alınmıştır.
class IsoCountryService {
  static const String _trAssetPath = 'assets/iso/i18n_iso_countries_tr.json';
  static const String _codesAssetPath =
      'assets/iso/i18n_iso_countries_codes.json';

  static bool _loaded = false;

  static final Map<String, String> _alpha2ToAlpha3 = <String, String>{};
  static final Map<String, String> _alpha3ToAlpha2 = <String, String>{};
  static final Map<String, String> _alpha2ToTrOfficial = <String, String>{};
  static final Map<String, String> _normalizedTrToAlpha2 = <String, String>{};

  // Backend/uygulama verilerinde görülen bazı ülke adları,
  // i18n tablosundaki karşılıktan farklı olabiliyor. Burada düzeltici alias'ler var.
  static final Map<String, String> _manualNormalizedToAlpha2 = <String, String>{
    // Cyprus
    'kibris cumhuriyeti': 'CY',
    // Cape Verde
    'yesil burun adalari': 'CV',
    // Eswatini
    'esvatini': 'SZ',
    // Timor-Leste
    'dogu timor': 'TL',
    // Czechia
    'cekya': 'CZ',
    // Congos
    'kongo cumhuriyeti': 'CG',
    'kongo demokratik cumhuriyeti': 'CD',
    // Palestine
    'filistin': 'PS',
    // Bhutan (i18n datasında "Butan" geçiyor)
    'bhutan': 'BT',
    // Lesotho (i18n datasında "Lesoto" geçiyor)
    'lesotho': 'LS',
  };

  /// Dosyaları asset'ten okur ve map'leri hazırlar.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;

    final trRaw = await rootBundle.loadString(_trAssetPath);
    final codesRaw = await rootBundle.loadString(_codesAssetPath);

    final trDecoded = jsonDecode(trRaw);
    final codesDecoded = jsonDecode(codesRaw);

    if (trDecoded is! Map || codesDecoded is! List) {
      throw const FormatException('ISO asset formatı beklenenden farklı.');
    }

    final countries = trDecoded['countries'];
    if (countries is! Map) {
      throw const FormatException('TR ISO asset içinde "countries" bulunamadı.');
    }

    // alpha2 -> alpha3
    for (final item in codesDecoded) {
      if (item is! List || item.length < 2) continue;
      final a2 = (item[0] ?? '').toString().trim().toUpperCase();
      final a3 = (item[1] ?? '').toString().trim().toUpperCase();
      if (a2.isEmpty || a3.isEmpty) continue;
      _alpha2ToAlpha3[a2] = a3;
      _alpha3ToAlpha2[a3] = a2;
    }

    // alpha2 -> TR isim (ve alias)
    for (final entry in countries.entries) {
      final alpha2 = entry.key.toString().trim().toUpperCase();
      if (alpha2.isEmpty) continue;

      void addName(String name, {bool isOfficial = false}) {
        final n = name.trim();
        if (n.isEmpty) return;

        // Official isim (ilk yazılan) olarak kaydedelim.
        if (isOfficial) {
          _alpha2ToTrOfficial.putIfAbsent(alpha2, () => n);
        }

        // Normalize edilmiş index: isim -> alpha2
        void indexValue(String value) {
          final key = normalizeName(value);
          if (key.isEmpty) return;
          // Aynı isim farklı alpha2'ye çakışırsa ilkini koruyoruz.
          _normalizedTrToAlpha2.putIfAbsent(key, () => alpha2);
        }

        indexValue(n);

        // Parantezli isimlerde ("Myanmar (Burma)" gibi) daha toleranslı eşleştirme için
        // parantezsiz ve parantez içi parçaları da index'leyelim.
        final noParens =
            n.replaceAll(RegExp(r'\([^)]*\)', unicode: true), ' ').trim();
        if (noParens.isNotEmpty && noParens != n) {
          indexValue(noParens);
        }
        for (final m in RegExp(r'\(([^)]*)\)', unicode: true).allMatches(n)) {
          final inner = (m.group(1) ?? '').trim();
          if (inner.isNotEmpty) indexValue(inner);
        }
      }

      final value = entry.value;
      if (value is String) {
        addName(value, isOfficial: true);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          final v = value[i];
          if (v is String) addName(v, isOfficial: i == 0);
        }
      }
    }

    _loaded = true;
  }

  /// TR ülke adından ISO Alpha-3 döndürür (örn. "Türkiye" -> "TUR").
  ///
  /// Bulamazsa null döner.
  static String? iso3FromTurkishName(String turkishName) {
    final alpha2 = alpha2FromTurkishName(turkishName);
    if (alpha2 == null) return null;
    return _alpha2ToAlpha3[alpha2];
  }

  /// TR ülke adından ISO Alpha-2 döndürür (örn. "Türkiye" -> "TR").
  static String? alpha2FromTurkishName(String turkishName) {
    if (!_loaded) return null;

    final raw = turkishName.trim();
    if (raw.isEmpty) return null;

    // Manuel alias'ler (normalize edilmiş) - hızlı yol.
    final manual = _manualNormalizedToAlpha2[normalizeName(raw)];
    if (manual != null) return manual;

    final candidates = <String>[
      raw,
      // Parantez içini at.
      raw.replaceAll(RegExp(r'\([^)]*\)', unicode: true), ' '),
      // Parantez içini ayrıca dene (örn. "Belarus (Beyaz Rusya)").
      ...RegExp(r'\(([^)]*)\)', unicode: true)
          .allMatches(raw)
          .map((m) => m.group(1) ?? '')
          .where((s) => s.trim().isNotEmpty),
    ];

    for (final c in candidates) {
      final key = normalizeName(c);
      final a2 = _normalizedTrToAlpha2[key];
      if (a2 != null) return a2;
    }

    return null;
  }

  /// ISO3 koddan Türkçe resmi ülke adını döndürür.
  static String? turkishNameFromIso3(String iso3) {
    if (!_loaded) return null;
    final a3 = iso3.trim().toUpperCase();
    if (a3.isEmpty) return null;

    final a2 = _alpha3ToAlpha2[a3];
    if (a2 == null) return null;
    return _alpha2ToTrOfficial[a2];
  }

  /// ISO2 -> ISO3 dönüşümü (örn. "TR" -> "TUR").
  static String? iso3FromAlpha2(String alpha2) {
    if (!_loaded) return null;
    final a2 = alpha2.trim().toUpperCase();
    if (a2.isEmpty) return null;
    return _alpha2ToAlpha3[a2];
  }

  /// ISO3 -> ISO2 dönüşümü (örn. "TUR" -> "TR").
  static String? alpha2FromIso3(String iso3) {
    if (!_loaded) return null;
    final a3 = iso3.trim().toUpperCase();
    if (a3.isEmpty) return null;
    return _alpha3ToAlpha2[a3];
  }

  /// Harita/veri eşleştirmesinde kullanılacak normalize metodu.
  /// - küçük harfe çevirir
  /// - Türkçe karakterleri sadeleştirir
  /// - boşlukları temizler
  /// - noktalama işaretlerini temizler
  static String normalizeName(String value) {
    var v = value.trim();
    if (v.isEmpty) return '';

    v = v.replaceAll('İ', 'i').replaceAll('I', 'i');
    v = v.toLowerCase();

    v = v
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');

    // i18n-iso-countries datasında (ve backend verilerinde) sık görülen aksanlı harfleri sadeleştir.
    // Örn: "São Tomé ve Príncipe" / "Sao Tome ve Principe" eşleştirmesi için gerekli.
    v = v
        .replaceAll('â', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('å', 'a')
        .replaceAll('æ', 'ae')
        .replaceAll('ç', 'c')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ñ', 'n')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ø', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ÿ', 'y');

    v = v.replaceAll(
      RegExp(r"[^\p{L}\p{N}\s]", unicode: true),
      ' ',
    );

    v = v.replaceAll(RegExp(r'\s+', unicode: true), ' ').trim();
    return v;
  }
}
