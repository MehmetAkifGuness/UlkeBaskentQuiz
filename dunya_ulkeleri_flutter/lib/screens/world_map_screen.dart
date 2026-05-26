import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../models/map_country_model.dart';
import '../providers/settings_provider.dart';
import '../providers/world_map_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'dictionary_screen.dart';

part 'world_map_screen/widgets.dart';
part 'world_map_screen/helpers.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  // Syncfusion Maps GeoJSON asset'i.
  // Not: Bu dosya Natural Earth / GeoJSON world countries datasından eklenecek.
  static const String _assetPath = 'assets/maps/world_map_simplified.json';

  late final MapZoomPanBehavior _zoomPanBehavior = MapZoomPanBehavior(
    enableDoubleTapZooming: true,
    enableMouseWheelZooming: true,
    minZoomLevel: 1,
    maxZoomLevel: 200,
  );

  late Future<_WorldMapLoadResult> _loadFuture = _loadWorldGeoJson(_assetPath);
  String? _lastSnackMessage;
  int _selectedIndex = -1;
  int? _lastTappedShapeIndex;
  int _mapsRefreshSeed = 0;
  bool _didQueueInitialMapsRefresh = false;

  @override
  void initState() {
    super.initState();

    // Ülke verilerini backend'den (dictionary endpoint) çek.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<WorldMapProvider>();
      provider.setContinentFilter('ALL');
      provider.loadAvailableCountries();
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
                          setState(() {
                            _loadFuture = _loadWorldGeoJson(_assetPath);
                          }),
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
                           setState(() {
                             _loadFuture = _loadWorldGeoJson(_assetPath);
                           }),
                     );
                   }

                  final countries = result.countries;
                  final bytes = result.bytes;

                  // Bazı cihazlarda/ilk açılışta SfMaps'in hit-test/gesture katmanı
                  // ilk frame'de doğru initialize olmayabiliyor (özellikle tab içinde).
                  // İlk çizimden hemen sonra 1 kez yeniden oluşturup etkileşimi garanti ediyoruz.
                  if (!_didQueueInitialMapsRefresh) {
                    _didQueueInitialMapsRefresh = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _mapsRefreshSeed++);
                    });
                  }

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
                        return conquered.withValues(alpha: 0.85);
                      }
                      // Varsayılan ülke rengi (fetih modunda ileride değişecek).
                      return AppColors.surface2.withValues(alpha: 0.70);
                    },
                  );

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLight),
                          color: AppColors.surface.withValues(alpha: 0.35),
                        ),
                        child: SfMaps(
                          key: ValueKey<int>(_mapsRefreshSeed),
                          layers: [
                            MapShapeLayer(
                              source: source,
                              zoomPanBehavior: _zoomPanBehavior,
                              strokeColor: AppColors.borderLight,
                              strokeWidth: 0.6,
                              selectedIndex: _selectedIndex,
                              selectionSettings: MapSelectionSettings(
                                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                                strokeColor: AppColors.primaryBlue,
                                strokeWidth: 1.4,
                              ),
                              onSelectionChanged: (int index) async {
                                // Syncfusion selection davranışı: Seçili shape'e tekrar dokunulursa
                                // callback -1 dönebilir. UX için son tıklanan index'i fallback olarak kullanıyoruz.
                                final effectiveIndex = index >= 0
                                    ? index
                                    : _lastTappedShapeIndex;
                                if (effectiveIndex == null) return;
                                _lastTappedShapeIndex = effectiveIndex;

                                if (effectiveIndex < 0 ||
                                    effectiveIndex >= countries.length) {
                                  provider.clearSelection();
                                  if (!mounted) return;
                                  setState(() => _selectedIndex = -1);
                                  return;
                                }

                                context
                                    .read<SettingsProvider>()
                                    .triggerButtonVibration();

                                final mapCountry = countries[effectiveIndex];
                                final props =
                                    mapCountry.extra ??
                                    const <String, dynamic>{};

                                if (!mounted) return;
                                setState(() => _selectedIndex = effectiveIndex);

                                try {
                                  await provider.selectCountryFromMapProperties(
                                    props,
                                  );
                                } catch (e) {
                                  _showSnackOnce(e.toString());
                                }

                                if (!context.mounted) return;

                                final matched = provider.selectedCountry;
                                final errText = (provider.errorMessage ?? '')
                                    .trim();

                                await _openSelectedCountrySheet(
                                  rootContext: context,
                                  mapCountry: mapCountry,
                                  matchedCountry: matched,
                                  errorMessage: errText.isEmpty
                                      ? null
                                      : errText,
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


