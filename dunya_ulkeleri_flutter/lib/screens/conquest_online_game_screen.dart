import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../models/conquest_session_dto.dart';
import '../models/map_country_model.dart';
import '../providers/conquest_multiplayer_provider.dart';
import '../providers/settings_provider.dart';
import '../services/country_match_service.dart';
import '../theme/app_theme.dart';
import '../utils/color_hex_utils.dart';
import '../utils/page_trasitions.dart';
import '../widgets/geo_background.dart';
import '../widgets/glass_card.dart';
import 'conquest_online_lobby_screen.dart';
import 'main_screen.dart';

part 'conquest_online_game_screen/view.dart';
part 'conquest_online_game_screen/map_section.dart';
part 'conquest_online_game_screen/widgets.dart';

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
    maxZoomLevel: 150,
  );

  late Future<_OnlineMapLoadResult> _loadFuture = _loadGeoJson();
  String? _lastSnackMessage;
  bool _didShowFinishedDialog = false;

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
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
        MapCountryModel(isoCode: isoCode, name: name, extra: props),
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
    final candidates = <String>['name', 'NAME', 'admin', 'ADMIN'];
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

    return mapCountries
        .map((shape) {
          final props = shape.extra;
          if (props == null) return null;
          final matched = matcher.matchFromMapProperties(props);
          return matched?.isoCode;
        })
        .toList(growable: false);
  }

  void _showFinishedDialog(ConquestMultiplayerProvider provider) {
    if (_didShowFinishedDialog) return;
    _didShowFinishedDialog = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final players = (provider.sessionState?.players ?? const []).toList()
        ..sort((a, b) {
          final byConquer = b.conqueredCount.compareTo(a.conqueredCount);
          if (byConquer != 0) return byConquer;
          return b.score.compareTo(a.score);
        });

      final winnerName = () {
        if (players.isEmpty) return null;
        final top = players.first.conqueredCount;
        final winners = players.where((p) => p.conqueredCount == top).toList();
        if (winners.length == 1) return winners.first.username;
        return 'Berabere: ${winners.map((p) => p.username ?? 'Oyuncu').join(', ')}';
      }();

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
                        Expanded(child: Text(p.username ?? 'Oyuncu')),
                        Text('Fetih: ${p.conqueredCount} • Can: ${p.remainingLives}'),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (!mounted) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      this.context,
                      FadePageRoute(page: const ConquestOnlineLobbyScreen()),
                    );
                  });
                },
                child: const Text('Lobiye Dön'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Ana menüye dönmek için ana ekrana gidiyoruz.
                  if (!mounted) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      this.context,
                      FadePageRoute(page: const MainScreen()),
                      (route) => false,
                    );
                  });
                },
                child: const Text('Ana Menü'),
              ),
            ],
          );
        },
      );
    });
  }

  void _retryLoadGeoJson() => setState(() {
        _loadFuture = _loadGeoJson();
      });

  @override
  Widget build(BuildContext context) => _ConquestOnlineGameView(state: this);

}

