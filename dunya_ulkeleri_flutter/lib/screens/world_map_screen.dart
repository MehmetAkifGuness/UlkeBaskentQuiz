import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../models/map_country_model.dart';
import '../providers/world_map_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'country_detail_screen.dart';
import '../services/country_match_service.dart'; // Kendi dosya yoluna göre düzenle

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  // Syncfusion Maps GeoJSON asset'i.
  // Not: Bu dosya Natural Earth / GeoJSON world countries datasından eklenecek.
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

  late final MapZoomPanBehavior _zoomPanBehavior = MapZoomPanBehavior(
    enableDoubleTapZooming: true,
    enableMouseWheelZooming: true,
    minZoomLevel: 1,
    maxZoomLevel: 15,
  );

  late Future<_WorldMapLoadResult> _loadFuture = _loadGeoJson();
  String? _lastSnackMessage;

  // Kıta filtresi seçildiğinde dünya yerine sadece o kıtanın GeoJSON'ını üretip
  // MapShapeSource'a veriyoruz. Böylece çizilecek shape sayısı azalır ve kasma düşer.
  String? _continentCacheSignature;
  Uint8List? _continentCacheBytes;
  List<MapCountryModel>? _continentCacheCountries;

  @override
  void initState() {
    super.initState();

    // Ülke verilerini backend'den (dictionary endpoint) çek.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WorldMapProvider>().loadAvailableCountries();
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
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    });
  }

  Future<_WorldMapLoadResult> _loadGeoJson() async {
    // Kullanıcı dostu hata için: dosyayı önce biz okuyup doğruluyoruz.
    final ByteData data = await rootBundle.load(_assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final Object decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! Map) {
      throw const FormatException(
        'GeoJSON bekleniyor (FeatureCollection). Dosya formatını kontrol edin.',
      );
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded as Map);
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
      final props = Map<String, dynamic>.from(propsValue as Map);

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

  static String _pickShapeDataField(List<Map<String, dynamic>> features) {
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

  static String? _pickContinent(Map<String, dynamic> props) {
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

  static String? _pickCapital(Map<String, dynamic> props) {
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
      builder: (sheetContext) {
        final effectiveName = matchedCountry?.name ?? mapCountry.name;
        final effectiveIso = matchedCountry?.isoCode ?? mapCountry.isoCode;
        final effectiveContinent = (matchedCountry?.continent ?? '').trim();
        final effectiveCapital = (matchedCountry?.capital ?? '').trim();
        final hasMatch = matchedCountry != null;

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
                  const SizedBox(height: 6),
                  Text(
                    'ISO: $effectiveIso',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (effectiveContinent.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Kıta: $effectiveContinent',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (effectiveCapital.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Başkent: $effectiveCapital',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!hasMatch)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        errorMessage ??
                            'Bu ülke uygulama verileriyle eşleştirilemedi.',
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
                          onPressed: hasMatch
                              ? () {
                                  // Sheet'i kapatıp detay ekranına geç.
                                  Navigator.of(sheetContext).pop();

                                  try {
                                    Navigator.push(
                                      rootContext,
                                      FadePageRoute(
                                        page: CountryDetailScreen(
                                          countryName: matchedCountry!.name,
                                          capitalName:
                                              matchedCountry!.capital ?? '—',
                                          continent:
                                              matchedCountry!.continent ?? '—',
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    // Constructor uyumsuzluğu vs. olursa ekranı bozmayalım.
                                    _showSnackOnce(
                                      'Ülke detay bağlantısı sonraki adımda bağlanacak.',
                                    );
                                  }
                                }
                              : null,
                          child: const Text(
                            'Detaya Git',
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

  Widget _continentFilterBar(BuildContext context) {
    final provider = context.watch<WorldMapProvider>();
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
                onSelected: (_) => provider.setContinentFilter(filter),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorldMapProvider>();
    final providerError = provider.errorMessage;
    if (providerError == null || providerError.trim().isEmpty) {
      _lastSnackMessage = null;
    } else {
      _showSnackOnce(providerError);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Dünya Haritası')),
      body: GeoBackground(
        safeArea: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            _continentFilterBar(context),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Bir ülkeye dokunarak bilgilerini öğren.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<_WorldMapLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
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
                      onRetry: () =>
                          setState(() => _loadFuture = _loadGeoJson()),
                    );
                  }

                  final result = snapshot.data;
                  if (result == null || result.countries.isEmpty) {
                    return _MapErrorCard(
                      title: 'Harita verisi hazır değil',
                      message:
                          'Şu an `assets/maps/world_map_simplified.json` içinde ülke geometrisi bulunmuyor.\n'
                          'Dosya eklendiğinde bu ekran otomatik çalışacak.',
                      onRetry: () =>
                          setState(() => _loadFuture = _loadGeoJson()),
                    );
                  }

                  final selectedFilter = provider.selectedContinentFilter
                      .trim();
                  final hasContinent = provider.availableCountries.any(
                    (c) => (c.continent ?? '').trim().isNotEmpty,
                  );

                  var countries = result.countries;
                  var bytes = result.bytes;

                  if (selectedFilter != 'ALL' && hasContinent) {
                    final signature =
                        '${selectedFilter}_${provider.availableCountries.length}_${result.countries.length}';

                    if (_continentCacheSignature != signature) {
                      final matcher = CountryMatchService(
                        availableCountries: provider.availableCountries,
                      );

                      final filteredFeatures = <Map<String, dynamic>>[];
                      final filteredCountries = <MapCountryModel>[];

                      for (var i = 0; i < result.countries.length; i++) {
                        final mapCountry = result.countries[i];
                        final props =
                            mapCountry.extra ?? const <String, dynamic>{};

                        final matched = matcher.matchFromMapProperties(props);
                        final continent = (matched?.continent ?? '').trim();
                        if (continent != selectedFilter) continue;

                        filteredCountries.add(mapCountry);
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
                      bytes = cachedBytes;
                      countries = cachedCountries;
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
                  final selected = provider.selectedIsoCode;
                  final selectedIndex = (selected == null)
                      ? -1
                      : countries.indexWhere((e) => e.isoCode == selected);

                  // Harita renkleri / seçimleri Provider state'i ile güncelleneceği için
                  // key ile yeniden çizimi garanti altına alıyoruz.
                  final MapShapeSource source = MapShapeSource.memory(
                    bytes,
                    shapeDataField: result.shapeDataField,
                    dataCount: countries.length,
                    primaryValueMapper: (int index) => countries[index].name,
                    shapeColorValueMapper: (int index) {
                      final c = countries[index];
                      final conquered =
                          provider.conqueredCountryColors[c.isoCode];
                      if (conquered != null) {
                        return conquered.withOpacity(0.85);
                      }
                      // Varsayılan ülke rengi (fetih modunda ileride değişecek).
                      return AppColors.surface2.withOpacity(0.70);
                    },
                  );

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
                              selectedIndex: selectedIndex,
                              selectionSettings: MapSelectionSettings(
                                color: AppColors.primaryBlue.withOpacity(0.25),
                                strokeColor: AppColors.primaryBlue,
                                strokeWidth: 1.4,
                              ),
                              onSelectionChanged: (int index) async {
                                final previousIndex = selectedIndex;

                                // Syncfusion selection davranışı: Aynı shape'e tekrar dokunulursa
                                // bazı sürümlerde `index == previousIndex`, bazılarında `-1` gelebiliyor.
                                // UX için: her dokunuşta (mümkünse) sheet açalım.
                                final effectiveIndex =
                                    index >= 0 ? index : previousIndex;

                                if (effectiveIndex < 0 ||
                                    effectiveIndex >= countries.length) {
                                  provider.clearSelection();
                                  return;
                                }

                                final mapCountry = countries[effectiveIndex];
                                final props =
                                    mapCountry.extra ??
                                    const <String, dynamic>{};

                                await provider.selectCountryFromMapProperties(
                                  props,
                                );

                                if (!context.mounted) return;

                                final matched = provider.selectedCountry;
                                final err = provider.errorMessage;

                                // Her dokunuşta kullanıcıya geri bildirim verelim:
                                // - Eşleşme varsa ülke bilgileri
                                // - Eşleşme yoksa / veri hazır değilse hata mesajı
                                final errText = (err ?? '').trim();
                                if (matched == null && errText.isEmpty) return;

                                await _openSelectedCountrySheet(
                                  rootContext: context,
                                  mapCountry: mapCountry,
                                  matchedCountry: matched,
                                  errorMessage: errText.isEmpty ? null : errText,
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
}

class _WorldMapLoadResult {
  final Uint8List bytes;
  final List<MapCountryModel> countries;
  final List<Map<String, dynamic>> features;
  final String shapeDataField;

  const _WorldMapLoadResult({
    required this.bytes,
    required this.countries,
    required this.features,
    required this.shapeDataField,
  });
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
