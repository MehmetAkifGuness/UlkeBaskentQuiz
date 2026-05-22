part of '../conquest_practice_screen.dart';

Future<_ConquestMapLoadResult> _loadConquestPracticeGeoJson(
  String assetPath,
) async {
  final ByteData data = await rootBundle.load(assetPath);
  final Uint8List bytes = data.buffer.asUint8List();
  final Object decoded = jsonDecode(utf8.decode(bytes));

  if (decoded is! Map) {
    throw const FormatException(
      'GeoJSON bekleniyor (FeatureCollection). Dosya formatını kontrol edin.',
    );
  }

  final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);
  final featuresValue = json['features'];
  if (featuresValue is! List) {
    throw const FormatException(
      'GeoJSON içinde "features" alanı bulunamadı. Dosyayı kontrol edin.',
    );
  }

  final List<Map<String, dynamic>> features = featuresValue
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);

  final String shapeDataField = _pickShapeDataField(features);

  final List<MapCountryModel> mapCountries = <MapCountryModel>[];
  final List<Map<String, dynamic>> keptFeatures = <Map<String, dynamic>>[];
  for (final feature in features) {
    final propsValue = feature['properties'];
    if (propsValue is! Map) continue;
    final props = Map<String, dynamic>.from(propsValue);

    final name = (props[shapeDataField] ?? '').toString().trim();
    if (name.isEmpty) continue;

    final iso = _pickIsoCode(props)?.trim();
    final isoCode = (iso == null || iso.isEmpty) ? name : iso;

    keptFeatures.add(feature);
    mapCountries.add(
      MapCountryModel(isoCode: isoCode, name: name, extra: props),
    );
  }

  return _ConquestMapLoadResult(
    bytes: bytes,
    mapCountries: mapCountries,
    features: keptFeatures,
    shapeDataField: shapeDataField,
  );
}

String _pickShapeDataField(List<Map<String, dynamic>> features) {
  const candidates = <String>[
    'name',
    'NAME',
    'admin',
    'ADMIN',
    'NAME_EN',
    'NAME_LONG',
    'SOVEREIGNT',
    'FORMAL_EN',
  ];

  for (final key in candidates) {
    final found = features.any((feature) {
      final props = feature['properties'];
      if (props is! Map) return false;
      final val = (props[key] ?? '').toString().trim();
      return val.isNotEmpty;
    });
    if (found) return key;
  }

  return 'name';
}

String? _pickIsoCode(Map<String, dynamic> props) {
  const candidates = <String>[
    'ISO3166-1-Alpha-3',
    'ISO3166-1-Alpha-2',
    'ISO_A3',
    'iso_a3',
    'ISO_A2',
    'iso_a2',
    'ADM0_A3',
    'adm0_a3',
    'id',
  ];

  for (final key in candidates) {
    final raw = props[key];
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty || value == '-99') continue;
    return value;
  }
  return null;
}

