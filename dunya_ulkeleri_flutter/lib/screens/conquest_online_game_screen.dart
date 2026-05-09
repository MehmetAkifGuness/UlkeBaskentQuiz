import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../models/conquest_session_dto.dart';
import '../models/map_country_model.dart';
import '../providers/conquest_multiplayer_provider.dart';
import '../services/country_match_service.dart';
import '../theme/app_theme.dart';
import '../utils/color_hex_utils.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'conquest_online_lobby_screen.dart';
import 'main_screen.dart';

class ConquestOnlineGameScreen extends StatefulWidget {
  const ConquestOnlineGameScreen({super.key});

  @override
  State<ConquestOnlineGameScreen> createState() =>
      _ConquestOnlineGameScreenState();
}

class _ConquestOnlineGameScreenState extends State<ConquestOnlineGameScreen> {
  static const String _assetPath = 'assets/maps/world_map_simplified.json';

  late final MapZoomPanBehavior _zoomPanBehavior = MapZoomPanBehavior(
    enableDoubleTapZooming: true,
    enableMouseWheelZooming: true,
    minZoomLevel: 1,
    maxZoomLevel: 15,
  );

  late Future<_OnlineMapLoadResult> _loadFuture = _loadGeoJson();
  String? _lastSnackMessage;
  bool _didShowFinishedDialog = false;
  int? _lastTappedShapeIndex;

  // Shape -> backend isoCode eşleştirmesini cache'liyoruz.
  List<String?>? _shapePlayableKeys;
  String? _shapePlayableSignature;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<ConquestMultiplayerProvider>();
      if (!provider.isConnected && provider.sessionId != null) {
        await provider.connectToCurrentSession();
      }
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
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });
  }

  Future<_OnlineMapLoadResult> _loadGeoJson() async {
    // Kullanıcı dostu hata için: dosyayı önce biz okuyup doğruluyoruz.
    final ByteData data = await rootBundle.load(_assetPath);
    final bytes = data.buffer.asUint8List();
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

    if (mapCountries.isEmpty) {
      throw const FormatException(
        'Harita verisi içinde ülke geometrileri bulunamadı (features boş).',
      );
    }

    return _OnlineMapLoadResult(
      bytes: bytes,
      shapeDataField: shapeDataField,
      mapCountries: mapCountries,
    );
  }

  static String _pickShapeDataField(List<Map<String, dynamic>> features) {
    // "name" varsa onu tercih et; yoksa ilk uygun string alanı seç.
    final candidates = <String>[
      'name',
      'NAME',
      'admin',
      'ADMIN',
    ];
    final firstProps = features
        .map((f) => f['properties'])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .cast<Map<String, dynamic>>()
        .toList(growable: false);

    for (final key in candidates) {
      final ok = firstProps.any((p) {
        final v = p[key];
        return v != null && v.toString().trim().isNotEmpty;
      });
      if (ok) return key;
    }

    for (final props in firstProps) {
      for (final entry in props.entries) {
        final v = entry.value;
        if (v is String && v.trim().isNotEmpty) return entry.key;
      }
    }

    return 'name';
  }

  static String? _pickIsoCode(Map<String, dynamic> props) {
    String? read(String key) {
      final v = props[key];
      final s = v?.toString().trim();
      if (s == null || s.isEmpty || s == '-99') return null;
      return s;
    }

    return read('ISO_A2') ??
        read('iso_a2') ??
        read('ISO3166-1-Alpha-2') ??
        read('ISO_A3') ??
        read('iso_a3') ??
        read('ISO3166-1-Alpha-3') ??
        read('ADM0_A3') ??
        read('adm0_a3') ??
        read('id');
  }

  static List<String?> _buildShapePlayableKeys({
    required List<MapCountryModel> mapCountries,
    required List<String> playableIsoCodes,
  }) {
    if (playableIsoCodes.isEmpty) {
      return List<String?>.filled(mapCountries.length, null, growable: false);
    }

    final available = playableIsoCodes
        .map((iso) => MapCountryModel(isoCode: iso, name: iso))
        .toList(growable: false);
    final matcher = CountryMatchService(availableCountries: available);

    return mapCountries.map((shape) {
      final props = shape.extra;
      if (props == null) return null;
      final matched = matcher.matchFromMapProperties(props);
      return matched?.isoCode;
    }).toList(growable: false);
  }

  void _showFinishedDialog(ConquestMultiplayerProvider provider) {
    if (_didShowFinishedDialog) return;
    _didShowFinishedDialog = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final players = (provider.sessionState?.players ?? const []).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      final winnerName = players.isNotEmpty ? players.first.username : null;

      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Maç Bitti'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (winnerName != null)
                  Text('Kazanan: $winnerName')
                else
                  const Text('Sonuç hazır değil.'),
                const SizedBox(height: 12),
                for (final p in players)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: hexToColor(p.colorHex ?? ''),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p.username ?? 'Oyuncu'),
                        ),
                        Text('Skor: ${p.score} • Can: ${p.remainingLives}'),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    FadePageRoute(page: const ConquestOnlineLobbyScreen()),
                  );
                },
                child: const Text('Lobiye Dön'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Ana menüye dönmek için ana ekrana gidiyoruz.
                  Navigator.pushAndRemoveUntil(
                    context,
                    FadePageRoute(page: const MainScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Ana Menü'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConquestMultiplayerProvider>();

    final error = provider.errorMessage;
    if (error != null) {
      _showSnackOnce(error);
      provider.clearError();
    }

    if (provider.isGameFinished) {
      _showFinishedDialog(provider);
    }

    final targetName = provider.currentTargetName ?? '...';
    final room = (provider.roomCode ?? '').trim();
    final status = (provider.sessionState?.status ?? '').toUpperCase();
    final players = provider.sessionState?.players ?? const [];
    final lastMessage = provider.sessionState?.lastEventMessage?.trim();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Online Dünya Fethi'),
        actions: [
          IconButton(
            tooltip: 'Lobi',
            icon: const Icon(Icons.meeting_room_outlined),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                FadePageRoute(page: const ConquestOnlineLobbyScreen()),
              );
            },
          ),
        ],
      ),
      body: GeoBackground(
        safeArea: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          physics: const BouncingScrollPhysics(),
          children: [
            GlassCard(
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (room.isNotEmpty)
                        Text(
                          'Oda: $room',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (room.isNotEmpty) const SizedBox(width: 12),
                      Text(
                        status.isEmpty ? '...' : status,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        provider.isConnected ? 'Bağlandı' : 'Bağlanıyor...',
                        style: TextStyle(
                          color: provider.isConnected
                              ? Colors.greenAccent
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (lastMessage != null && lastMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      lastMessage,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skorlar',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (players.isEmpty)
                    const Text(
                      'Oyuncu listesi bekleniyor...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final p in players)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _ScoreChip(player: p),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bir ülkeye dokunarak cevabını gönder.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<_OnlineMapLoadResult>(
              future: _loadFuture,
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
                    onRetry: () => setState(() => _loadFuture = _loadGeoJson()),
                  );
                }

                final result = snapshot.data;
                if (result == null) {
                  return _MapErrorCard(
                    title: 'Harita yüklenemedi',
                    message: 'Harita verisi hazır değil.',
                    onRetry: () => setState(() => _loadFuture = _loadGeoJson()),
                  );
                }

                final mapCountries = result.mapCountries;
                final playableIso = provider.sessionState?.playableIsoCodes ?? const <String>[];

                final signature =
                    '${playableIso.join(',')}_${mapCountries.length}';
                if (_shapePlayableKeys == null ||
                    _shapePlayableKeys!.length != mapCountries.length ||
                    _shapePlayableSignature != signature) {
                  _shapePlayableKeys = _buildShapePlayableKeys(
                    mapCountries: mapCountries,
                    playableIsoCodes: playableIso,
                  );
                  _shapePlayableSignature = signature;
                }

                final shapeKeys = _shapePlayableKeys ??
                    List<String?>.filled(mapCountries.length, null);

                final colors = provider.conqueredCountryColorsAsColors;

                // Boyama/target değişince map yeniden çizilsin diye key kullan.
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
                            zoomPanBehavior: _zoomPanBehavior,
                            strokeColor: AppColors.borderLight,
                            strokeWidth: 0.6,
                            selectionSettings: MapSelectionSettings(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.18),
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

                              final key = shapeKeys[effectiveIndex];
                              if (key == null) {
                                _showSnackOnce('Bu bölge maç kapsamında değil.');
                                return;
                              }

                              final tapped = mapCountries[effectiveIndex];
                              final props = tapped.extra ?? const <String, dynamic>{};
                              await provider.submitOnlineAnswerFromMapProperties(
                                props,
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
            if (!provider.isConnected)
              const Text(
                'Bağlantı kuruluyor... (WebSocket)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final ConquestPlayerState player;

  const _ScoreChip({required this.player});

  @override
  Widget build(BuildContext context) {
    final String name = (player.username ?? 'Oyuncu').toString();
    final int score = player.score;
    final int lives = player.remainingLives;
    final String colorHex = (player.colorHex ?? '').toString();

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: hexToColor(colorHex),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(
                i < lives ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: AppColors.errorRed.withValues(alpha: i < lives ? 0.95 : 0.32),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnlineMapLoadResult {
  final Uint8List bytes;
  final String shapeDataField;
  final List<MapCountryModel> mapCountries;

  const _OnlineMapLoadResult({
    required this.bytes,
    required this.shapeDataField,
    required this.mapCountries,
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
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ),
        ],
      ),
    );
  }
}
