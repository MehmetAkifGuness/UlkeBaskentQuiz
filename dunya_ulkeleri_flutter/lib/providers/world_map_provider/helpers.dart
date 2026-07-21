part of '../world_map_provider.dart';

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
