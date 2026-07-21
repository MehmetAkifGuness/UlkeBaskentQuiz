part of '../country_detail_screen.dart';

final _worldMapSource = MapShapeSource.asset(
  'assets/maps/world_map_simplified.json',
  shapeDataField: 'name',
);

extension _CountryDetailScreenLocationCardImpl on CountryDetailScreenState {
  Widget _buildLocationCardImpl() {
    final latLng = countryLatLng;
    final label = '${widget.countryName}, $displayedContinent'.trim();

    if (latLng == null) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          color: AppColors.surface2.withValues(alpha: 0.35),
        ),
        child: const Text(
          'Konum bilgisi bulunamadı.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final zoomPanBehavior = MapZoomPanBehavior(
      focalLatLng: latLng,
      zoomLevel: 3,
      minZoomLevel: 1,
      maxZoomLevel: 10,
      enableDoubleTapZooming: false,
      enableMouseWheelZooming: false,
      showToolbar: false,
      enablePinching: false,
      enablePanning: false,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            Positioned.fill(
              child: SfMaps(
                layers: [
                  MapShapeLayer(
                    source: _worldMapSource,
                    zoomPanBehavior: zoomPanBehavior,
                    strokeColor: AppColors.borderLight,
                    strokeWidth: 0.5,
                    color: AppColors.surface2.withValues(alpha: 0.25),
                    initialMarkersCount: 1,
                    markerBuilder: (context, index) {
                      return MapMarker(
                        latitude: latLng.latitude,
                        longitude: latLng.longitude,
                        alignment: Alignment.bottomCenter,
                        offset: const Offset(0, -4),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primaryBlue,
                          size: 26,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.surface.withValues(alpha: 0.85),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
