import 'package:collection/collection.dart';

import '../models/map_country_model.dart';
import 'iso_country_service.dart';

/// Haritadan gelen ülke adını / ISO kodunu uygulamadaki ülke verisiyle eşleştirmek için.
///
/// Not: Bu servis ADIM 2 için sadece eşleştirme sorumluluğunu üstlenir.
/// Ülke listesi (availableCountries) Provider tarafından yüklenir.
class CountryMatchService {
  final List<MapCountryModel> availableCountries;

  CountryMatchService({required this.availableCountries});

  static final Map<String, String> _aliasMap = <String, String>{
    'turkey': 'türkiye',
    'turkiye': 'türkiye',
    'united states of america': 'united states',
    'usa': 'united states',
    'russia': 'russia',
    'czechia': 'czech republic',
    'south korea': 'south korea',
    'north korea': 'north korea',
    'ivory coast': "cote d ivoire",
    'democratic republic of the congo': 'dr congo',
    'republic of the congo': 'congo',
  };

  /// Harita/veri eşleştirmesinde kullanılacak normalize metodu.
  /// - küçük harfe çevirir
  /// - Türkçe karakterleri sadeleştirir
  /// - boşlukları temizler
  /// - noktalama işaretlerini temizler
  String normalizeName(String value) {
    var v = value.trim();
    if (v.isEmpty) return '';

    // Türkçe "İ/I" edge-case'lerini basitleştir.
    v = v.replaceAll('İ', 'i').replaceAll('I', 'i');

    v = v.toLowerCase();

    // Türkçe karakterleri sadeleştir.
    v = v
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');

    // Sık görülen aksanlı harfleri sadeleştir (minimal set).
    v = v
        .replaceAll('â', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('å', 'a')
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
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ÿ', 'y');

    // Noktalama vb. temizle (Unicode property escape ile).
    v = v.replaceAll(
      RegExp(r"[^\p{L}\p{N}\s]", unicode: true),
      ' ',
    );

    // Boşlukları normalize et.
    v = v.replaceAll(RegExp(r'\s+', unicode: true), ' ').trim();
    return v;
  }

  MapCountryModel? matchByIsoCode(String isoCode) {
    final code = isoCode.trim().toUpperCase();
    if (code.isEmpty) return null;

    MapCountryModel? find(String candidate) {
      final needle = candidate.trim().toUpperCase();
      if (needle.isEmpty) return null;
      return availableCountries.firstWhereOrNull((c) {
      final cCode = c.isoCode.trim().toUpperCase();
      return cCode.isNotEmpty && cCode == needle;
    });
    }

    // 1) Direkt karşılaştır
    final direct = find(code);
    if (direct != null) return direct;

    // 2) ISO2 <-> ISO3 çeviri dene (IsoCountryService yüklüyse).
    if (code.length == 2) {
      final iso3 = IsoCountryService.iso3FromAlpha2(code);
      if (iso3 != null) {
        final byIso3 = find(iso3);
        if (byIso3 != null) return byIso3;
      }
    } else if (code.length == 3) {
      final iso2 = IsoCountryService.alpha2FromIso3(code);
      if (iso2 != null) {
        final byIso2 = find(iso2);
        if (byIso2 != null) return byIso2;
      }
    }

    return null;
  }

  MapCountryModel? matchByName(String countryName) {
    final normalized = normalizeName(countryName);
    if (normalized.isEmpty) return null;

    // Alias'ler UI/back-end diline göre farklı gelebilir. Eşleştirmede her zaman
    // normalize edilmiş karşılıklar üzerinden ilerliyoruz.
    final alias = normalizeName(_aliasMap[normalized] ?? normalized);

    // 1) Tam eşleşme
    final exact = availableCountries.firstWhereOrNull((c) {
      final n = normalizeName(c.name);
      return n == alias || n == normalized;
    });
    if (exact != null) return exact;

    // 2) Daha toleranslı eşleşme (kısa isim / uzun isim farkı için)
    return availableCountries.firstWhereOrNull((c) {
      final n = normalizeName(c.name);
      if (n.isEmpty) return false;
      return n.contains(alias) || alias.contains(n);
    });
  }

  MapCountryModel? matchFromMapProperties(Map<String, dynamic> properties) {
    String? readKey(List<String> keys) {
      for (final key in keys) {
        final raw = properties[key];
        final value = raw?.toString().trim();
        if (value != null && value.isNotEmpty && value != '-99') return value;
      }
      return null;
    }

    final iso = readKey(const [
      'ISO3166-1-Alpha-3',
      'ISO3166-1-Alpha-2',
      'iso_a3',
      'ISO_A3',
      'ADM0_A3',
      'adm0_a3',
      'iso_a2',
      'ISO_A2',
      'id',
    ]);
    if (iso != null) {
      final byIso = matchByIsoCode(iso);
      if (byIso != null) return byIso;

      // Bazı GeoJSON kaynaklarında sadece ISO2 gelebilir. Biz uygulama tarafında ISO3
      // ile çalışıyorsak (özellikle harita eşleştirmesinde), ISO2 -> ISO3 çevirmeyi dene.
      if (iso.trim().length == 2) {
        final iso3 = IsoCountryService.iso3FromAlpha2(iso);
        if (iso3 != null) {
          final byIso3 = matchByIsoCode(iso3);
          if (byIso3 != null) return byIso3;
        }
      }
    }

    final name = readKey(const ['name', 'NAME', 'admin', 'ADMIN']);
    if (name != null) {
      final byName = matchByName(name);
      if (byName != null) return byName;
    }

    return null;
  }
}
