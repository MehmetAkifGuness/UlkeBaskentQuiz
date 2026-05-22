import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../models/bot_difficulty.dart';
import '../models/map_country_model.dart';
import '../providers/conquest_provider.dart';
import '../providers/auth_provider.dart';
import '../services/country_match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';

part 'conquest_bot_screen/view.dart';
part 'conquest_bot_screen/map_section.dart';
part 'conquest_bot_screen/widgets.dart';

class ConquestBotScreen extends StatefulWidget {
  const ConquestBotScreen({super.key});

  @override
  State<ConquestBotScreen> createState() => _ConquestBotScreenState();
}

class _ConquestBotScreenState extends State<ConquestBotScreen> {
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

  static const List<_ColorOption> _playerColors = <_ColorOption>[
    _ColorOption('Kırmızı', Colors.red),
    _ColorOption('Mavi', Colors.blue),
    _ColorOption('Yeşil', Colors.green),
    _ColorOption('Mor', Colors.purple),
    _ColorOption('Turuncu', Colors.orange),
  ];

  static const List<_ColorOption> _botColors = <_ColorOption>[
    _ColorOption('Kırmızı', Colors.redAccent),
    _ColorOption('Sarı', Colors.amber),
    _ColorOption('Mor', Colors.deepPurple),
    _ColorOption('Turkuaz', Colors.cyan),
    _ColorOption('Pembe', Colors.pink),
  ];

  late final MapZoomPanBehavior _zoomPanBehavior = MapZoomPanBehavior(
    enableDoubleTapZooming: true,
    enableMouseWheelZooming: true,
    minZoomLevel: 1,
    maxZoomLevel: 150,
  );

  late Future<_ConquestMapLoadResult> _loadFuture = _loadGeoJson();

  late final TextEditingController _playerNameController =
      TextEditingController();

  String _selectedContinent = 'ALL';
  Color _selectedPlayerColor = Colors.blue;
  Color _selectedBotColor = Colors.redAccent;
  BotDifficulty _selectedDifficulty = BotDifficulty.medium;

  String? _lastSnackMessage;
  int? _lastTappedShapeIndex;

  // Shape -> playable (provider isoKey) eşleştirmesini ekranda cache’liyoruz.
  List<String?>? _shapePlayableKeys;
  String? _shapePlayableSignature;

  ConquestProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider ??= context.read<ConquestProvider>();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final username = context.read<AuthProvider>().username;
      _playerNameController.text = (username == null || username.trim().isEmpty)
          ? 'Sen'
          : username.trim();

      context.read<ConquestProvider>().initializePracticeMode();
    });
  }

  @override
  void dispose() {
    // ADIM 4: Ekrandan çıkarken bot timer çalışmaya devam etmesin.
    _provider?.stopBotMatch();
    _playerNameController.dispose();
    super.dispose();
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
      _loadConquestBotGeoJson(_assetPath);

  Widget _continentPickerBar(BuildContext context, {required bool enabled}) {
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
                selected: _selectedContinent == filter,
                onSelected: enabled
                    ? (_) => setState(() => _selectedContinent = filter)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _colorPickerBar({
    required String title,
    required List<_ColorOption> options,
    required Color selected,
    required ValueChanged<Color> onChanged,
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final opt in options)
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
                        selected: selected.toARGB32() == opt.color.toARGB32(),
                        onSelected: enabled
                            ? (_) => onChanged(opt.color)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _difficultyPickerBar(BuildContext context, {required bool enabled}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bot Zorluğu',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final diff in BotDifficulty.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(diff.displayName),
                        selected: _selectedDifficulty == diff,
                        onSelected: enabled
                            ? (_) => setState(() => _selectedDifficulty = diff)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMatch(ConquestProvider provider) async {
    provider.configureBotMatch(
      playerColor: _selectedPlayerColor,
      botColor: _selectedBotColor,
      difficulty: _selectedDifficulty,
      playerName: _playerNameController.text,
    );
    provider.setContinentFilter(_selectedContinent);
    provider.startBotMatch();
  }

  void _retryLoadGeoJson() => setState(() => _loadFuture = _loadGeoJson());

  void _setSelectedPlayerColor(Color c) =>
      setState(() => _selectedPlayerColor = c);

  void _setSelectedBotColor(Color c) => setState(() => _selectedBotColor = c);

  @override
  Widget build(BuildContext context) => _ConquestBotScreenView(state: this);


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

