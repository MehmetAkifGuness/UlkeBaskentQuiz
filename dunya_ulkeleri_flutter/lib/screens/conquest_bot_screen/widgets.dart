part of '../conquest_bot_screen.dart';

class _ConquestMapLoadResult {
  final Uint8List bytes;
  final List<MapCountryModel> mapCountries;
  final String shapeDataField;

  const _ConquestMapLoadResult({
    required this.bytes,
    required this.mapCountries,
    required this.shapeDataField,
  });
}

class _ColorOption {
  final String label;
  final Color color;

  const _ColorOption(this.label, this.color);
}

class _ScorePill extends StatelessWidget {
  final String title;
  final int score;
  final int conquered;
  final int lives;
  final Color color;

  const _ScorePill({
    required this.title,
    required this.score,
    required this.conquered,
    required this.lives,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Skor: $score',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fetih: $conquered',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.favorite, size: 16, color: AppColors.errorRed),
              const SizedBox(width: 6),
              Text(
                'Can: $lives',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    i < lives ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: AppColors.errorRed.withValues(
                      alpha: i < lives ? 0.95 : 0.32,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _MapErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Tekrar Dene',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<_ConquestMapLoadResult> _loadConquestBotGeoJson(String assetPath) async {
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
  for (final feature in features) {
    final propsValue = feature['properties'];
    if (propsValue is! Map) continue;
    final props = Map<String, dynamic>.from(propsValue);

    final name = (props[shapeDataField] ?? '').toString().trim();
    if (name.isEmpty) continue;

    final iso = _pickIsoCode(props)?.trim();
    final isoCode = (iso == null || iso.isEmpty) ? name : iso;

    mapCountries.add(
      MapCountryModel(isoCode: isoCode, name: name, extra: props),
    );
  }

  return _ConquestMapLoadResult(
    bytes: bytes,
    mapCountries: mapCountries,
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

