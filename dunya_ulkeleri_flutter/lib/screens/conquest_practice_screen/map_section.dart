part of '../conquest_practice_screen.dart';

class _ConquestPracticeMapSection extends StatelessWidget {
  final _ConquestPracticeScreenState state;
  final ConquestProvider provider;

  const _ConquestPracticeMapSection({
    required this.state,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ConquestMapLoadResult>(
      future: state._loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }

        if (snapshot.hasError) {
          final errorText = snapshot.error.toString();
          final isMissingAsset = errorText.contains('Unable to load asset') &&
              errorText.contains(_ConquestPracticeScreenState._assetPath);

          return _MapErrorCard(
            title: 'Harita yüklenemedi',
            message: isMissingAsset
                ? 'Harita verisi bulunamadı. Lütfen assets/maps/world_map_simplified.json dosyasını ekleyin.'
                : 'Dünya haritası verisi okunamadı. Dosya formatını kontrol edin.',
            onRetry: state._retryLoadGeoJson,
          );
        }

        final result = snapshot.data;
        if (result == null || result.mapCountries.isEmpty) {
          return _MapErrorCard(
            title: 'Harita verisi hazır değil',
            message:
                'Şu an assets/maps/world_map_simplified.json içinde ülke geometrisi bulunmuyor.',
            onRetry: state._retryLoadGeoJson,
          );
        }

        var mapCountries = result.mapCountries;
        var mapBytes = result.bytes;

        final selectedFilter = provider.selectedContinentFilter.trim();
        final hasContinent = provider.playableCountries.any(
          (c) => (c.continent ?? '').trim().isNotEmpty,
        );

        // "Kıta bazlı harita": ALL değilse, seçili kıtaya ait ülkelerin feature'larından
        // yeni bir GeoJSON üretip haritaya onu ver.
        if (selectedFilter != 'ALL' && hasContinent) {
          final signature =
              '${selectedFilter}_${provider.playableCountries.length}_${result.mapCountries.length}';

          if (state._continentCacheSignature != signature) {
            final matcher = CountryMatchService(
              availableCountries: provider.playableCountries,
            );

            final filteredFeatures = <Map<String, dynamic>>[];
            final filteredCountries = <MapCountryModel>[];

            for (var i = 0; i < result.mapCountries.length; i++) {
              final shape = result.mapCountries[i];
              final props = shape.extra ?? const <String, dynamic>{};

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
              state._continentCacheBytes = Uint8List.fromList(
                utf8.encode(jsonStr),
              );
              state._continentCacheCountries = filteredCountries;
            } else {
              state._continentCacheBytes = null;
              state._continentCacheCountries = null;
            }

            state._continentCacheSignature = signature;
          }

          final cachedBytes = state._continentCacheBytes;
          final cachedCountries = state._continentCacheCountries;
          if (cachedBytes != null &&
              cachedCountries != null &&
              cachedCountries.isNotEmpty) {
            mapBytes = cachedBytes;
            mapCountries = cachedCountries;
          } else {
            return _MapErrorCard(
              title: 'Kıta haritası oluşturulamadı',
              message: 'Seçili kıta için harita eşleştirmesi yapılamadı.\n'
                  'Not: Bu özellik için ülke verilerinde ISO/kıta bilgisi uyumlu olmalı.',
              onRetry: state._retryLoadGeoJson,
            );
          }
        }

        // Map ülkelerini provider ülkeleriyle bir kez eşleştirip cache’leyelim.
        final signature =
            '${provider.selectedContinentFilter}|${provider.playableCountries.length}';
        final playableKeys = state._shapePlayableKeys;
        if (playableKeys == null ||
            playableKeys.length != mapCountries.length ||
            state._shapePlayableSignature != signature) {
          state._shapePlayableKeys =
              _ConquestPracticeScreenState._buildShapePlayableKeys(
            mapCountries: mapCountries,
            playableCountries: provider.playableCountries,
          );
          state._shapePlayableSignature = signature;
        }

        final shapeKeys = state._shapePlayableKeys ??
            List<String?>.filled(mapCountries.length, null, growable: false);

        final targetKey =
            provider.isGameActive ? provider.targetCountry?.isoCode : null;

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
                return conqueredColor.withValues(alpha: 0.85);
              }
              if (provider.wrongFlashIsoCode == key) {
                return Colors.redAccent.withValues(alpha: 0.35);
              }
              if (targetKey != null && key == targetKey) {
                return provider.playerColor.withValues(alpha: 0.25);
              }
            }

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
                layers: [
                  MapShapeLayer(
                    source: source,
                    zoomPanBehavior: state._zoomPanBehavior,
                    strokeColor: AppColors.borderLight,
                    strokeWidth: 0.6,
                    selectionSettings: MapSelectionSettings(
                      color: AppColors.primaryBlue.withValues(alpha: 0.18),
                      strokeColor: AppColors.primaryBlue,
                      strokeWidth: 1.2,
                    ),
                    onSelectionChanged: (int index) async {
                      // Syncfusion seçim davranışı: Seçili shape'e tekrar dokunulursa
                      // callback -1 dönebilir. Pratik modda aynı ülkeye tekrar dokunmayı
                      // engellememek için son tıklanan index'i fallback olarak kullanıyoruz.
                      final effectiveIndex =
                          index >= 0 ? index : state._lastTappedShapeIndex;
                      if (effectiveIndex == null) return;

                      state._lastTappedShapeIndex = effectiveIndex;

                      if (effectiveIndex < 0 ||
                          effectiveIndex >= mapCountries.length) {
                        return;
                      }

                      final key = shapeKeys[effectiveIndex];
                      if (key == null) {
                        state._showSnackOnce('Bu bölge oyun kapsamında değil.');
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
    );
  }
}


