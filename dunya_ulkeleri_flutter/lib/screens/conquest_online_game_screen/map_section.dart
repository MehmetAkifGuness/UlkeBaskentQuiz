part of '../conquest_online_game_screen.dart';

class _ConquestOnlineGameMapSection extends StatelessWidget {
  final _ConquestOnlineGameScreenState state;
  final ConquestMultiplayerProvider provider;

  const _ConquestOnlineGameMapSection({
    required this.state,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OnlineMapLoadResult>(
      future: state._loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          final message = snapshot.error.toString();
          final isMissingAsset = message.contains('Unable to load asset');
          return _MapErrorCard(
            title: 'Harita yüklenemedi',
            message: isMissingAsset
                ? 'Harita verisi bulunamadı. Lütfen assets/maps/world_map_simplified.json dosyasını ekleyin.'
                : 'Dünya haritası verisi okunamadı. Dosya formatını kontrol edin.',
            onRetry: state._retryLoadGeoJson,
          );
        }

        final result = snapshot.data;
        if (result == null) {
          return _MapErrorCard(
            title: 'Harita yüklenemedi',
            message: 'Harita verisi hazır değil.',
            onRetry: state._retryLoadGeoJson,
          );
        }

        final mapCountries = result.mapCountries;
        final playableIso =
            provider.sessionState?.playableIsoCodes ?? const <String>[];

        final signature = '${playableIso.join(',')}_${mapCountries.length}';
        if (state._shapePlayableKeys == null ||
            state._shapePlayableKeys!.length != mapCountries.length ||
            state._shapePlayableSignature != signature) {
          state._shapePlayableKeys =
              _ConquestOnlineGameScreenState._buildShapePlayableKeys(
            mapCountries: mapCountries,
            playableIsoCodes: playableIso,
          );
          state._shapePlayableSignature = signature;
        }

        final shapeKeys = state._shapePlayableKeys ??
            List<String?>.filled(mapCountries.length, null, growable: false);

        final colors = provider.conqueredCountryColorsAsColors;

        final MapShapeSource source = MapShapeSource.memory(
          result.bytes,
          shapeDataField: result.shapeDataField,
          dataCount: mapCountries.length,
          primaryValueMapper: (int index) => mapCountries[index].name,
          shapeColorValueMapper: (int index) {
            final key = shapeKeys[index];
            if (key != null) {
              final conquered = colors[key];
              if (conquered != null) {
                return conquered.withValues(alpha: 0.85);
              }
            }
            return AppColors.surface2.withValues(alpha: 0.70);
          },
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
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
                      // Syncfusion: Tapping an already-selected shape again can yield `-1` (unselected).
                      if (index < 0 || index >= mapCountries.length) {
                        return;
                      }

                      context
                          .read<SettingsProvider>()
                          .triggerButtonVibration();

                      final key = shapeKeys[index];
                      if (key == null) {
                        state._showSnackOnce('Bu bölge maç kapsamında değil.');
                        return;
                      }

                      final tapped = mapCountries[index];
                      final props = tapped.extra ?? const <String, dynamic>{};
                      await provider.submitOnlineAnswerFromMapProperties(props);
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
