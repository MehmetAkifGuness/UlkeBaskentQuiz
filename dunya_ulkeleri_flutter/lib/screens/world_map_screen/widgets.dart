part of '../world_map_screen.dart';

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

class _WorldMapLayer extends StatefulWidget {
  final _WorldMapLoadResult result;
  final MapZoomPanBehavior zoomPanBehavior;
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;

  const _WorldMapLayer({
    super.key,
    required this.result,
    required this.zoomPanBehavior,
    required this.selectedIndex,
    required this.onSelectionChanged,
  });

  @override
  State<_WorldMapLayer> createState() => _WorldMapLayerState();
}

class _WorldMapLayerState extends State<_WorldMapLayer> {
  late final List<MapCountryModel> _countries = widget.result.countries;
  late final MapShapeSource _source;

  @override
  void initState() {
    super.initState();
    final provider = context.read<WorldMapProvider>();

    _source = MapShapeSource.memory(
      widget.result.bytes,
      shapeDataField: widget.result.shapeDataField,
      dataCount: _countries.length,
      primaryValueMapper: (int index) => _countries[index].name,
      shapeColorValueMapper: (int index) {
        final c = _countries[index];
        final conquered = provider.conqueredCountryColors[c.isoCode];
        if (conquered != null) return conquered.withValues(alpha: 0.85);
        return AppColors.surface2.withValues(alpha: 0.70);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<WorldMapProvider>();

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
                source: _source,
                zoomPanBehavior: widget.zoomPanBehavior,
                strokeColor: AppColors.borderLight,
                strokeWidth: 0.6,
                selectedIndex: widget.selectedIndex,
                selectionSettings: MapSelectionSettings(
                  color: AppColors.primaryBlue.withValues(alpha: 0.25),
                  strokeColor: AppColors.primaryBlue,
                  strokeWidth: 1.4,
                ),
                onSelectionChanged: widget.onSelectionChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

