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

        final geometryKey = Object.hash(mapBytes, mapCountries);
        final visualKey = Object.hash(
          provider.targetCountry?.isoCode,
          Object.hashAll(shapeKeys),
          Object.hashAll(
            provider.conqueredCountryColors.entries.map(
              (entry) => Object.hash(entry.key, entry.value.toARGB32()),
            ),
          ),
        );
        if (state._mapSource == null ||
            state._mapSourceGeometryKey != geometryKey ||
            state._mapSourceVisualKey != visualKey) {
          state._mapSource = MapShapeSource.memory(
            mapBytes,
            shapeDataField: result.shapeDataField,
            dataCount: mapCountries.length,
            primaryValueMapper: (int index) => mapCountries[index].name,
            shapeColorValueMapper: (int index) {
              final keys = state._shapePlayableKeys;
              final mapIso = mapCountries[index].isoCode.trim().toUpperCase();
              final matchedKey = keys != null && index < keys.length
                  ? keys[index]
                  : null;
              final key = matchedKey ??
                  (mapIso.isEmpty || mapIso == '-99' ? null : mapIso);

              if (key != null) {
                final conqueredColor = provider.conqueredCountryColors[key];
                if (conqueredColor != null) {
                  return conqueredColor.withValues(alpha: 0.85);
                }
                if (provider.isGameActive &&
                    key == provider.targetCountry?.isoCode) {
                  return AppColors.yellow.withValues(alpha: 0.38);
                }
              }

              return AppColors.surface2.withValues(alpha: 0.70);
            },
          );
          state._mapSourceGeometryKey = geometryKey;
          state._mapSourceVisualKey = visualKey;
        }
        final source = state._mapSource!;
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
                      color: Colors.transparent,
                      strokeColor: Colors.transparent,
                      strokeWidth: 0,
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

                      final mapIso =
                          mapCountries[effectiveIndex].isoCode.trim().toUpperCase();
                      final key = shapeKeys[effectiveIndex] ??
                          (mapIso.isEmpty || mapIso == '-99' ? null : mapIso);
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


