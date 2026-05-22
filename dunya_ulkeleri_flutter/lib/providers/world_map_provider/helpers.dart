part of '../world_map_provider.dart';

String? _readAuthToken() {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return null;

  try {
    return Provider.of<AuthProvider>(ctx, listen: false).token;
  } catch (_) {
    return null;
  }
}

String? _readFirstNonEmpty(
  Map<String, dynamic> props,
  List<String> keys,
) {
  for (final key in keys) {
    final raw = props[key];
    final value = raw?.toString().trim();
    if (value != null && value.isNotEmpty && value != '-99') return value;
  }
  return null;
}

String? _toEnglishContinent(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return null;

  return switch (v) {
    'Avrupa' => 'Europe',
    'Asya' => 'Asia',
    'Afrika' => 'Africa',
    'Kuzey Amerika' => 'North America',
    'Güney Amerika' => 'South America',
    'Okyanusya' => 'Oceania',
    _ => v,
  };
}

List<MapCountryModel> _fallbackCountries() {
  // ADIM 2: Endpoint hazır değilse minimum örnek veri ile ekran çalışsın.
  // TODO: Backend'den ISO + kıta + başkent ile tam liste getirilecek.
  return const <MapCountryModel>[
    MapCountryModel(
      isoCode: 'TUR',
      name: 'Türkiye',
      continent: 'Asia',
      capital: 'Ankara',
    ),
    MapCountryModel(
      isoCode: 'USA',
      name: 'United States',
      continent: 'North America',
      capital: 'Washington, D.C.',
    ),
    MapCountryModel(
      isoCode: 'DEU',
      name: 'Germany',
      continent: 'Europe',
      capital: 'Berlin',
    ),
    MapCountryModel(
      isoCode: 'FRA',
      name: 'France',
      continent: 'Europe',
      capital: 'Paris',
    ),
  ];
}
