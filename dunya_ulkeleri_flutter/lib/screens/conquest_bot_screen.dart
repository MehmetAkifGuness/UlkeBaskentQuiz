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
    maxZoomLevel: 15,
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
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });
  }

  Future<_ConquestMapLoadResult> _loadGeoJson() async {
    final ByteData data = await rootBundle.load(_assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final Object decoded = jsonDecode(utf8.decode(bytes));

    if (decoded is! Map) {
      throw const FormatException(
        'GeoJSON bekleniyor (FeatureCollection). Dosya formatını kontrol edin.',
      );
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);
    final featuresValue = json['features'];
    if (featuresValue is! List) {
      throw const FormatException(
        'GeoJSON içinde "features" alanı bulunamadı. Dosyayı kontrol edin.',
      );
    }

    final List<Map<String, dynamic>> features = featuresValue
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);

    final String shapeDataField = _pickShapeDataField(features);

    final List<MapCountryModel> mapCountries = <MapCountryModel>[];
    for (final feature in features) {
      final propsValue = feature['properties'];
      if (propsValue is! Map) continue;
      final props = Map<String, dynamic>.from(propsValue);

      final name = (props[shapeDataField] ?? '').toString().trim();
      if (name.isEmpty) continue;

      final iso = _pickIsoCode(props)?.trim();
      final isoCode = (iso == null || iso.isEmpty) ? name : iso;

      mapCountries.add(
        MapCountryModel(
          isoCode: isoCode,
          name: name,
          extra: props,
        ),
      );
    }

    return _ConquestMapLoadResult(
      bytes: bytes,
      mapCountries: mapCountries,
      shapeDataField: shapeDataField,
    );
  }

  static String _pickShapeDataField(List<Map<String, dynamic>> features) {
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
                onSelected: enabled ? (_) => setState(() => _selectedContinent = filter) : null,
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
                        onSelected: enabled ? (_) => onChanged(opt.color) : null,
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
                        onSelected:
                            enabled ? (_) => setState(() => _selectedDifficulty = diff) : null,
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConquestProvider>();
    final err = provider.errorMessage;
    if (err == null || err.trim().isEmpty) {
      _lastSnackMessage = null;
    } else {
      _showSnackOnce(err);
    }

    final isStarted = provider.isGameActive && provider.isVsBotMode;
    final targetName = provider.targetCountry?.name ?? '—';
    final total = provider.playableCountries.length;
    final conquered = provider.conqueredIsoCodes.length;

    final human = provider.humanPlayer;
    final bot = provider.botPlayer;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Botlara Karşı Dünya Fethi')),
      body: GeoBackground(
        safeArea: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            if (!isStarted) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maç Ayarları',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _playerNameController,
                        decoration: InputDecoration(
                          labelText: 'Oyuncu Adı',
                          labelStyle: const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.surface2.withOpacity(0.55),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue.withOpacity(0.65),
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Kıta Seçimi',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _continentPickerBar(context, enabled: !provider.isLoading),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading
                              ? null
                              : () => _startMatch(provider),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text(
                            'BAŞLA',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _difficultyPickerBar(context, enabled: !provider.isLoading),
              const SizedBox(height: 10),
              _colorPickerBar(
                title: 'Oyuncu Rengi',
                options: _playerColors,
                selected: _selectedPlayerColor,
                enabled: !provider.isLoading,
                onChanged: (c) => setState(() => _selectedPlayerColor = c),
              ),
              const SizedBox(height: 10),
              _colorPickerBar(
                title: 'Bot Rengi',
                options: _botColors,
                selected: _selectedBotColor,
                enabled: !provider.isLoading,
                onChanged: (c) => setState(() => _selectedBotColor = c),
              ),
              const SizedBox(height: 10),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hedef: $targetName',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Haritada hedef ülkeyi bul ve botlardan önce dokun.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ScorePill(
                              title: human?.name ?? 'Sen',
                              score: human?.score ?? provider.correctCount,
                              color: human?.color ?? _selectedPlayerColor,
                              conquered: human?.conqueredCount ?? 0,
                              lives: human?.remainingLives ?? 3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ScorePill(
                              title: bot?.name ?? 'Bot',
                              score: bot?.score ?? 0,
                              color: bot?.color ?? _selectedBotColor,
                              conquered: bot?.conqueredCount ?? 0,
                              lives: bot?.remainingLives ?? 3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Fethedilen: $conquered / $total',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: provider.progressRatio.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            human?.color ?? _selectedPlayerColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (provider.botTimer != null && provider.isWaitingForAnswer)
                        const Text(
                          'Bot düşünüyor...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if ((provider.lastRoundMessage ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            provider.lastRoundMessage!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => provider.resetGame(),
                              child: const Text(
                                'Sıfırla',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => provider.stopBotMatch(),
                              child: const Text(
                                'Bitir',
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
              const SizedBox(height: 10),
            ],
            Expanded(
              child: FutureBuilder<_ConquestMapLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryBlue),
                    );
                  }

                  if (snapshot.hasError) {
                    final err = snapshot.error?.toString() ?? '';
                    final isMissingAsset =
                        err.contains('Unable to load asset') ||
                            err.contains('Unable to load') ||
                            err.contains('FlutterError');

                    return _MapErrorCard(
                      title: 'Harita yüklenemedi',
                      message: isMissingAsset
                          ? 'Harita verisi bulunamadı. Lütfen assets/maps/world_map_simplified.json dosyasını ekleyin.'
                          : 'Dünya haritası verisi okunamadı. Dosya formatını kontrol edin.',
                      onRetry: () => setState(() => _loadFuture = _loadGeoJson()),
                    );
                  }

                  final result = snapshot.data;
                  if (result == null || result.mapCountries.isEmpty) {
                    return _MapErrorCard(
                      title: 'Harita verisi hazır değil',
                      message:
                          'Şu an assets/maps/world_map_simplified.json içinde ülke geometrisi bulunmuyor.',
                      onRetry: () => setState(() => _loadFuture = _loadGeoJson()),
                    );
                  }

                  final mapCountries = result.mapCountries;

                  // Map ülkelerini provider ülkeleriyle bir kez eşleştirip cache’leyelim.
                  final signature =
                      '${provider.selectedContinentFilter}|${provider.playableCountries.length}';
                  final playableKeys = _shapePlayableKeys;
                  if (playableKeys == null ||
                      playableKeys.length != mapCountries.length ||
                      _shapePlayableSignature != signature) {
                    _shapePlayableKeys = _buildShapePlayableKeys(
                      mapCountries: mapCountries,
                      playableCountries: provider.playableCountries,
                    );
                    _shapePlayableSignature = signature;
                  }

                  final shapeKeys = _shapePlayableKeys ??
                      List<String?>.filled(mapCountries.length, null);

                  final MapShapeSource source = MapShapeSource.memory(
                    result.bytes,
                    shapeDataField: result.shapeDataField,
                    dataCount: mapCountries.length,
                    primaryValueMapper: (int index) => mapCountries[index].name,
                    shapeColorValueMapper: (int index) {
                      final key = shapeKeys[index];

                      if (key != null) {
                        final conqueredColor = provider.conqueredCountryColors[key];
                        if (conqueredColor != null) {
                          return conqueredColor.withOpacity(0.85);
                        }
                        if (provider.wrongFlashIsoCode == key) {
                          return Colors.redAccent.withOpacity(0.35);
                        }
                      }

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
                              selectionSettings: MapSelectionSettings(
                                color: AppColors.primaryBlue.withOpacity(0.18),
                                strokeColor: AppColors.primaryBlue,
                                strokeWidth: 1.2,
                              ),
                              onSelectionChanged: (int index) async {
                                final effectiveIndex =
                                    index >= 0 ? index : _lastTappedShapeIndex;
                                if (effectiveIndex == null) return;
                                _lastTappedShapeIndex = effectiveIndex;

                                if (effectiveIndex < 0 ||
                                    effectiveIndex >= mapCountries.length) {
                                  return;
                                }

                                if (!isStarted) {
                                  _showSnackOnce(
                                    'Başlamak için "Başla" butonuna bas.',
                                  );
                                  return;
                                }

                                final key = shapeKeys[effectiveIndex];
                                if (key == null) {
                                  _showSnackOnce('Bu bölge maç kapsamında değil.');
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<String?> _buildShapePlayableKeys({
    required List<MapCountryModel> mapCountries,
    required List<MapCountryModel> playableCountries,
  }) {
    if (playableCountries.isEmpty) {
      return List<String?>.filled(mapCountries.length, null, growable: false);
    }

    final matcher = CountryMatchService(availableCountries: playableCountries);
    return mapCountries.map((shape) {
      final props = shape.extra;
      if (props == null) return null;
      final matched = matcher.matchFromMapProperties(props);
      return matched?.isoCode;
    }).toList(growable: false);
  }
}

class _ConquestMapLoadResult {
  final Uint8List bytes;
  final List<MapCountryModel> mapCountries;
  final String shapeDataField;

  const _ConquestMapLoadResult({
    required this.bytes,
    required this.mapCountries,
    required this.shapeDataField,
  });
}

class _ColorOption {
  final String label;
  final Color color;

  const _ColorOption(this.label, this.color);
}

class _ScorePill extends StatelessWidget {
  final String title;
  final int score;
  final int conquered;
  final int lives;
  final Color color;

  const _ScorePill({
    required this.title,
    required this.score,
    required this.conquered,
    required this.lives,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Skor: $score',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fetih: $conquered',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.favorite,
                size: 16,
                color: AppColors.errorRed,
              ),
              const SizedBox(width: 6),
              Text(
                'Can: $lives',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    i < lives ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: AppColors.errorRed.withValues(
                      alpha: i < lives ? 0.95 : 0.32,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
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
