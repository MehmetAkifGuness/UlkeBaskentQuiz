import 'package:syncfusion_flutter_maps/maps.dart';

import 'country_catalog_service.dart';

class CountryDetailSnapshot {
  final String countryName;
  final String alpha2;
  final String capitalName;
  final String continent;
  final String flagEmoji;
  final MapLatLng? countryLatLng;

  const CountryDetailSnapshot({
    required this.countryName,
    required this.alpha2,
    required this.capitalName,
    required this.continent,
    required this.flagEmoji,
    required this.countryLatLng,
  });
}

class CountryDetailService {
  final CountryCatalogService _catalogService = CountryCatalogService();

  Future<void> preload() => _catalogService.preload();

  Future<CountryDetailSnapshot> load({
    required String countryName,
    required String? alpha2,
    required String fallbackCapital,
    required String fallbackContinent,
  }) async {
    await _catalogService.preload();
    final normalizedAlpha2 = alpha2?.trim().toUpperCase();
    final entry = normalizedAlpha2 != null && normalizedAlpha2.isNotEmpty
        ? _catalogService.lookupByAlpha2(normalizedAlpha2)
        : _catalogService.lookupByCountryName(countryName);

    final resolvedAlpha2 = (entry != null && entry.alpha2.isNotEmpty)
        ? entry.alpha2
        : normalizedAlpha2 ?? '';

    final resolvedCountryName =
        (entry != null && entry.countryName.isNotEmpty)
            ? entry.countryName
            : countryName;
    final resolvedCapitalName = _firstNonEmpty([
      entry?.capitalName,
      fallbackCapital,
    ]);
    final resolvedContinent = _firstNonEmpty([
      entry?.continent,
      fallbackContinent,
    ]);
    final flagEmoji = entry?.flagEmoji ??
        CountryCatalogService.flagEmojiFromAlpha2(resolvedAlpha2) ??
        '🏳️';

    return CountryDetailSnapshot(
      countryName: resolvedCountryName,
      alpha2: resolvedAlpha2,
      capitalName: resolvedCapitalName,
      continent: resolvedContinent,
      flagEmoji: flagEmoji,
      countryLatLng: entry?.countryLatLng,
    );
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return 'Bilinmiyor';
  }
}
