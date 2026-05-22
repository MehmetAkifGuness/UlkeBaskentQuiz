part of '../world_map_screen.dart';

Future<_WorldMapLoadResult> _loadWorldGeoJson(String assetPath) async {
  // Kullanıcı dostu hata için: dosyayı önce biz okuyup doğruluyoruz.
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

  final List<Map<String, dynamic>> rawFeatures = featuresValue
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);

  final String shapeDataField = _pickShapeDataField(rawFeatures);

  final List<MapCountryModel> countries = <MapCountryModel>[];
  final List<Map<String, dynamic>> features = <Map<String, dynamic>>[];
  for (final feature in rawFeatures) {
    final propsValue = feature['properties'];
    if (propsValue is! Map) continue;
    final props = Map<String, dynamic>.from(propsValue);

    final name = (props[shapeDataField] ?? '').toString().trim();
    if (name.isEmpty) continue;

    final iso = _pickIsoCode(props)?.trim();
    final isoCode = (iso == null || iso.isEmpty) ? name : iso;

    final continent = _pickContinent(props);
    final capital = _pickCapital(props);

    // Kıta haritası üretmek için feature'ları da saklıyoruz.
    features.add(feature);
    countries.add(
      MapCountryModel(
        isoCode: isoCode,
        name: name,
        continent: continent,
        capital: capital,
        extra: props,
      ),
    );
  }

  return _WorldMapLoadResult(
    bytes: bytes,
    countries: countries,
    features: features,
    shapeDataField: shapeDataField,
  );
}

String _pickShapeDataField(List<Map<String, dynamic>> features) {
  // Ülke adı alanı farklı kaynaklarda farklı olabilir. En yaygın olanları dene.
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

  // Fallback: ilk feature'daki string property.
  if (features.isNotEmpty) {
    final props = features.first['properties'];
    if (props is Map) {
      for (final entry in props.entries) {
        final val = entry.value?.toString().trim() ?? '';
        if (val.isNotEmpty) return entry.key.toString();
      }
    }
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
    'ADM0_ISO',
    'adm0_iso',
    'cca3',
    'countryCode',
    'code',
    'CODE',
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

String? _pickContinent(Map<String, dynamic> props) {
  const candidates = <String>[
    'continent',
    'CONTINENT',
    'region',
    'REGION_UN',
  ];
  for (final key in candidates) {
    final raw = props[key];
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty || value == '-99') continue;
    return value;
  }
  return null;
}

String? _pickCapital(Map<String, dynamic> props) {
  const candidates = <String>['capital', 'CAPITAL', 'CAPITAL_EN'];
  for (final key in candidates) {
    final raw = props[key];
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty || value == '-99') continue;
    return value;
  }
  return null;
}

Future<void> _openSelectedCountrySheet({
  required BuildContext rootContext,
  required MapCountryModel mapCountry,
  required MapCountryModel? matchedCountry,
  required String? errorMessage,
}) async {
  await showModalBottomSheet<void>(
    context: rootContext,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    useRootNavigator: true,
    builder: (sheetContext) {
      final effectiveName = matchedCountry?.name ?? mapCountry.name;
      final detailQuery = effectiveName.trim();

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effectiveName,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                if (errorMessage != null && errorMessage.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Kapat',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: detailQuery.isEmpty
                            ? null
                            : () {
                                Navigator.of(sheetContext).pop();
                                Navigator.push(
                                  rootContext,
                                  FadePageRoute(
                                    page: DictionaryScreen(
                                      initialQuery: detailQuery,
                                    ),
                                  ),
                                );
                              },
                        child: const Text(
                          'Detay',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
