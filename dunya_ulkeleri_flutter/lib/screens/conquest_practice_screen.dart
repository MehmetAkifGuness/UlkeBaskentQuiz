import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../models/map_country_model.dart';
import '../providers/conquest_provider.dart';
import '../services/country_match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';

class ConquestPracticeScreen extends StatefulWidget {
  const ConquestPracticeScreen({super.key});

  @override
  State<ConquestPracticeScreen> createState() => _ConquestPracticeScreenState();
}

class _ConquestPracticeScreenState extends State<ConquestPracticeScreen> {
  static const String _assetPath = 'assets/maps/world_map_simplified.json';

  static const List<String> _continentFilters = <String>[
    'ALL',
    'Europe',
    'Asia',
    'Africa',
    'North America',
    'South America',
    'Oceania',
  ];

  static const List<_PlayerColorOption> _playerColors = <_PlayerColorOption>[
    _PlayerColorOption('Kırmızı', Colors.red),
    _PlayerColorOption('Mavi', Colors.blue),
    _PlayerColorOption('Yeşil', Colors.green),
    _PlayerColorOption('Mor', Colors.purple),
    _PlayerColorOption('Turuncu', Colors.orange),
  ];

  late final MapZoomPanBehavior _zoomPanBehavior = MapZoomPanBehavior(
    enableDoubleTapZooming: true,
    enableMouseWheelZooming: true,
    minZoomLevel: 1,
    maxZoomLevel: 15,
  );

  late Future<_ConquestMapLoadResult> _loadFuture = _loadGeoJson();
  String? _lastSnackMessage;
  int? _lastTappedShapeIndex;

  // Shape -> playable (provider isoKey) eşleştirmesini ekranda cache’liyoruz.
  List<String?>? _shapePlayableKeys;
  String? _shapePlayableSignature;

  // Kıta filtresi seçildiyse sadece o kıtanın GeoJSON'ını üretip MapShapeSource'a veriyoruz.
  // Böylece "her kıtanın kendi haritası" hissi gelir ve çizilecek shape sayısı azalır.
  String? _continentCacheSignature;
  Uint8List? _continentCacheBytes;
  List<MapCountryModel>? _continentCacheCountries;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ConquestProvider>().initializePracticeMode();
    });
  }

  void _showSnackOnce(String message) {
    if (message.trim().isEmpty) return;
    if (_lastSnackMessage == message) return;
    _lastSnackMessage = message;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });
  }

  Future<_ConquestMapLoadResult> _loadGeoJson() async {
    final ByteData data = await rootBundle.load(_assetPath);
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
        MapCountryModel(
          isoCode: isoCode,
          name: name,
          extra: props,
        ),
      );
    }

    return _ConquestMapLoadResult(
      bytes: bytes,
      mapCountries: mapCountries,
      features: keptFeatures,
      shapeDataField: shapeDataField,
    );
  }

  static String _pickShapeDataField(List<Map<String, dynamic>> features) {
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

  static String? _pickIsoCode(Map<String, dynamic> props) {
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

  Widget _continentFilterBar(BuildContext context) {
    final provider = context.watch<ConquestProvider>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final filter in _continentFilters)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(filter),
                selected: provider.selectedContinentFilter == filter,
                onSelected: (_) {
                  provider.setContinentFilter(filter);
                  setState(() {
                    _lastTappedShapeIndex = null;
                    _shapePlayableKeys = null;
                    _shapePlayableSignature = null;
                    _continentCacheSignature = null;
                    _continentCacheBytes = null;
                    _continentCacheCountries = null;
                  });
                  _zoomPanBehavior.reset();
                },
              ),
            ),
         ],
       ),
    );
  }

  Widget _colorPickerBar(BuildContext context) {
    final provider = context.watch<ConquestProvider>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final opt in _playerColors)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: opt.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(opt.label),
                  ],
                ),
                selected:
                    provider.playerColor.toARGB32() == opt.color.toARGB32(),
                onSelected: (_) => provider.setPlayerColor(opt.color),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConquestProvider>();
    final err = provider.errorMessage;
    if (err == null || err.trim().isEmpty) {
      _lastSnackMessage = null;
    } else {
      _showSnackOnce(err);
    }

    final targetName = provider.targetCountry?.name ?? '—';
    final total = provider.playableCountries.length;
    final conquered = provider.conqueredIsoCodes.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Dünya Fethi Pratik')),
      body: GeoBackground(
        safeArea: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            _continentFilterBar(context),
            const SizedBox(height: 10),
            _colorPickerBar(context),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hedef: $targetName',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Haritada hedef ülkeyi bul ve dokun.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fethedilen: $conquered / $total',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: provider.progressRatio.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppColors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          provider.playerColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            label: 'Doğru',
                            value: '${provider.correctCount}',
                            accent: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'Yanlış',
                            value: '${provider.wrongCount}',
                            accent: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'Seri',
                            value: '${provider.streak}',
                            accent: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () {
                                    provider.resetGame();
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textDark,
                              side:
                                  const BorderSide(color: AppColors.borderLight),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Sıfırla',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: provider.isGameActive
                              ? ElevatedButton(
                                  onPressed: () => provider.stopGame(),
                                  child: const Text(
                                    'Bitir',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: provider.isLoading
                                      ? null
                                      : () => provider.startGame(),
                                  child: const Text(
                                    'Başla',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<_ConquestMapLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryBlue),
                    );
                  }

                  if (snapshot.hasError) {
                    final errorText = snapshot.error.toString();
                    final isMissingAsset =
                        errorText.contains('Unable to load asset') &&
                        errorText.contains(_assetPath);

                    return _MapErrorCard(
                      title: 'Harita yüklenemedi',
                      message: isMissingAsset
                          ? 'Harita verisi bulunamadı. Lütfen assets/maps/world_map_simplified.json dosyasını ekleyin.'
                          : 'Dünya haritası verisi okunamadı. Dosya formatını kontrol edin.',
                      onRetry: () => setState(() => _loadFuture = _loadGeoJson()),
                    );
                  }

                  final result = snapshot.data;
                  if (result == null || result.mapCountries.isEmpty) {
                    return _MapErrorCard(
                      title: 'Harita verisi hazır değil',
                      message:
                          'Şu an assets/maps/world_map_simplified.json içinde ülke geometrisi bulunmuyor.',
                      onRetry: () => setState(() => _loadFuture = _loadGeoJson()),
                    );
                  }

                  var mapCountries = result.mapCountries;
                  var mapBytes = result.bytes;

                  final selectedFilter =
                      provider.selectedContinentFilter.trim();
                  final hasContinent = provider.playableCountries.any(
                    (c) => (c.continent ?? '').trim().isNotEmpty,
                  );

                  // "Kıta bazlı harita": ALL değilse, seçili kıtaya ait ülkelerin
                  // feature'larından yeni bir GeoJSON üretip haritaya onu ver.
                  if (selectedFilter != 'ALL' && hasContinent) {
                    final signature =
                        '${selectedFilter}_${provider.playableCountries.length}_${result.mapCountries.length}';

                    if (_continentCacheSignature != signature) {
                      final matcher = CountryMatchService(
                        availableCountries: provider.playableCountries,
                      );

                      final filteredFeatures = <Map<String, dynamic>>[];
                      final filteredCountries = <MapCountryModel>[];

                      for (var i = 0; i < result.mapCountries.length; i++) {
                        final shape = result.mapCountries[i];
                        final props =
                            shape.extra ?? const <String, dynamic>{};

                        final matched = matcher.matchFromMapProperties(props);
                        if (matched == null) continue;

                        final continent = (matched.continent ?? '').trim();
                        if (continent != selectedFilter) continue;

                        filteredCountries.add(shape);
                        filteredFeatures.add(result.features[i]);
                      }

                      if (filteredFeatures.isNotEmpty) {
                        final geojson = <String, dynamic>{
                          'type': 'FeatureCollection',
                          'features': filteredFeatures,
                        };
                        final jsonStr = jsonEncode(geojson);
                        _continentCacheBytes = Uint8List.fromList(
                          utf8.encode(jsonStr),
                        );
                        _continentCacheCountries = filteredCountries;
                      } else {
                        _continentCacheBytes = null;
                        _continentCacheCountries = null;
                      }

                      _continentCacheSignature = signature;
                    }

                    final cachedBytes = _continentCacheBytes;
                    final cachedCountries = _continentCacheCountries;
                    if (cachedBytes != null &&
                        cachedCountries != null &&
                        cachedCountries.isNotEmpty) {
                      mapBytes = cachedBytes;
                      mapCountries = cachedCountries;
                    } else {
                      return _MapErrorCard(
                        title: 'Kıta haritası oluşturulamadı',
                        message:
                            'Seçili kıta için harita eşleştirmesi yapılamadı.\n'
                            'Not: Bu özellik için ülke verilerinde ISO/kıta bilgisi uyumlu olmalı.',
                        onRetry: () =>
                            setState(() => _loadFuture = _loadGeoJson()),
                      );
                    }
                  }

                  // Map ülkelerini provider ülkeleriyle bir kez eşleştirip cache’leyelim.
                  final signature =
                      '${provider.selectedContinentFilter}|${provider.playableCountries.length}';
                  final playableKeys = _shapePlayableKeys;
                  if (playableKeys == null ||
                      playableKeys.length != mapCountries.length ||
                      _shapePlayableSignature != signature) {
                    _shapePlayableKeys = _buildShapePlayableKeys(
                      mapCountries: mapCountries,
                      playableCountries: provider.playableCountries,
                    );
                    _shapePlayableSignature = signature;
                  }

                  final shapeKeys = _shapePlayableKeys ?? List<String?>.filled(
                    mapCountries.length,
                    null,
                  );

                  final targetKey = provider.isGameActive
                      ? provider.targetCountry?.isoCode
                      : null;

                  final MapShapeSource source = MapShapeSource.memory(
                    mapBytes,
                    shapeDataField: result.shapeDataField,
                    dataCount: mapCountries.length,
                    primaryValueMapper: (int index) => mapCountries[index].name,
                    shapeColorValueMapper: (int index) {
                      final key = shapeKeys[index];

                      if (key != null) {
                        final conqueredColor = provider.conqueredCountryColors[key];
                        if (conqueredColor != null) {
                          return conqueredColor.withOpacity(0.85);
                        }
                        if (provider.wrongFlashIsoCode == key) {
                          return Colors.redAccent.withOpacity(0.35);
                        }
                        if (targetKey != null && key == targetKey) {
                          return provider.playerColor.withOpacity(0.25);
                        }
                      }

                      return AppColors.surface2.withOpacity(0.70);
                    },
                  );

                  // Harita yeniden çizimi için (boyama/target değişince) key kullan.
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLight),
                          color: AppColors.surface.withOpacity(0.35),
                        ),
                        child: SfMaps(
                          layers: [
                            MapShapeLayer(
                              source: source,
                              zoomPanBehavior: _zoomPanBehavior,
                              strokeColor: AppColors.borderLight,
                              strokeWidth: 0.6,
                              selectionSettings: MapSelectionSettings(
                                color: AppColors.primaryBlue.withOpacity(0.18),
                                strokeColor: AppColors.primaryBlue,
                                strokeWidth: 1.2,
                              ),
                              onSelectionChanged: (int index) async {
                                // Syncfusion seçim davranışı: Seçili shape'e tekrar dokunulursa
                                // callback -1 dönebilir. Pratik modda aynı ülkeye tekrar dokunmayı
                                // engellememek için son tıklanan index'i fallback olarak kullanıyoruz.
                                final effectiveIndex =
                                    index >= 0 ? index : _lastTappedShapeIndex;
                                if (effectiveIndex == null) return;

                                _lastTappedShapeIndex = effectiveIndex;

                                if (effectiveIndex < 0 ||
                                    effectiveIndex >= mapCountries.length) {
                                  return;
                                }

                                final mapCountry = mapCountries[effectiveIndex];
                                await provider.handleCountryTap(
                                  mapCountry.extra ?? const <String, dynamic>{},
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<String?> _buildShapePlayableKeys({
    required List<MapCountryModel> mapCountries,
    required List<MapCountryModel> playableCountries,
  }) {
    if (playableCountries.isEmpty) {
      return List<String?>.filled(mapCountries.length, null, growable: false);
    }

    final matcher = CountryMatchService(availableCountries: playableCountries);
    return mapCountries.map((shape) {
      final props = shape.extra;
      if (props == null) return null;
      final matched = matcher.matchFromMapProperties(props);
      return matched?.isoCode;
    }).toList(growable: false);
  }
}

class _ConquestMapLoadResult {
  final Uint8List bytes;
  final List<MapCountryModel> mapCountries;
  final List<Map<String, dynamic>> features;
  final String shapeDataField;

  const _ConquestMapLoadResult({
    required this.bytes,
    required this.mapCountries,
    required this.features,
    required this.shapeDataField,
  });
}

class _PlayerColorOption {
  final String label;
  final Color color;

  const _PlayerColorOption(this.label, this.color);
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
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
