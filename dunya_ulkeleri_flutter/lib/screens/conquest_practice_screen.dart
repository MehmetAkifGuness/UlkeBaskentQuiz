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

part 'conquest_practice_screen/geojson.dart';
part 'conquest_practice_screen/map_section.dart';
part 'conquest_practice_screen/view.dart';
part 'conquest_practice_screen/widgets.dart';

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
    maxZoomLevel: 150,
  );

  late Future<_ConquestMapLoadResult> _loadFuture = _loadGeoJson();
  String? _lastSnackMessage;
  int? _lastTappedShapeIndex;

  // Shape -> playable (provider isoKey) eşleştirmesini ekranda cache’liyoruz.
  List<String?>? _shapePlayableKeys;
  String? _shapePlayableSignature;

  // Kıta filtresi seçildiyse sadece o kıtanın GeoJSON'ını üretip MapShapeSource'a veriyoruz.
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
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    });
  }

  Future<_ConquestMapLoadResult> _loadGeoJson() =>
      _loadConquestPracticeGeoJson(_assetPath);

  void _retryLoadGeoJson() => setState(() {
        _loadFuture = _loadGeoJson();
      });

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
  Widget build(BuildContext context) => _ConquestPracticeView(state: this);

  static List<String?> _buildShapePlayableKeys({
    required List<MapCountryModel> mapCountries,
    required List<MapCountryModel> playableCountries,
  }) {
    if (playableCountries.isEmpty) {
      return List<String?>.filled(mapCountries.length, null, growable: false);
    }

    final matcher = CountryMatchService(availableCountries: playableCountries);
    return mapCountries
        .map((shape) {
          final props = shape.extra;
          if (props == null) return null;
          final matched = matcher.matchFromMapProperties(props);
          return matched?.isoCode;
        })
        .toList(growable: false);
  }
}
