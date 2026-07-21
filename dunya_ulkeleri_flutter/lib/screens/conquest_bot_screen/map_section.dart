part of '../conquest_bot_screen.dart';

class _ConquestBotMapSection extends StatelessWidget {
  final _ConquestBotScreenState state;
  final ConquestProvider provider;
  final bool isStarted;

  const _ConquestBotMapSection({
    required this.state,
    required this.provider,
    required this.isStarted,
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
          final err = snapshot.error?.toString() ?? '';
          final isMissingAsset = err.contains('Unable to load asset') ||
              err.contains('Unable to load') ||
              err.contains('FlutterError');

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

        final mapCountries = result.mapCountries;

        // Map ülkelerini provider ülkeleriyle bir kez eşleştirip cache’leyelim.
        final signature =
            '${provider.selectedContinentFilter}|${provider.playableCountries.length}';
        final playableKeys = state._shapePlayableKeys;
        if (playableKeys == null ||
            playableKeys.length != mapCountries.length ||
            state._shapePlayableSignature != signature) {
          state._shapePlayableKeys = _ConquestBotScreenState._buildShapePlayableKeys(
            mapCountries: mapCountries,
            playableCountries: provider.playableCountries,
          );
          state._shapePlayableSignature = signature;
        }

        final shapeKeys = state._shapePlayableKeys ??
            List<String?>.filled(mapCountries.length, null, growable: false);

        final geometryKey = Object.hash(result.bytes, mapCountries);
        final visualKey = Object.hash(
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
            result.bytes,
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
                      final effectiveIndex =
                          index >= 0 ? index : state._lastTappedShapeIndex;
                      if (effectiveIndex == null) return;
                      state._lastTappedShapeIndex = effectiveIndex;

                      if (effectiveIndex < 0 ||
                          effectiveIndex >= mapCountries.length) {
                        return;
                      }

                      if (!isStarted) {
                        state._showSnackOnce(
                          'Başlamak için "Başla" butonuna bas.',
                        );
                        return;
                      }

                      final mapIso =
                          mapCountries[effectiveIndex].isoCode.trim().toUpperCase();
                      final key = shapeKeys[effectiveIndex] ??
                          (mapIso.isEmpty || mapIso == '-99' ? null : mapIso);
                      if (key == null) {
                        state._showSnackOnce('Bu bölge maç kapsamında değil.');
                        return;
                      }

                      final mapCountry = mapCountries[effectiveIndex];
                      await provider.handleHumanCountryTap(
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


