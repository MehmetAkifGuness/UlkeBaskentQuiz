import 'dart:convert';

import 'package:dunya_ulkeleri_flutter/models/dictionary_model.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_maps/maps.dart';

class CountryCatalogEntry {
  final String countryName;
  final String capitalName;
  final String continent;
  final String alpha2;
  final double? latitude;
  final double? longitude;

  const CountryCatalogEntry({
    required this.countryName,
    required this.capitalName,
    required this.continent,
    required this.alpha2,
    required this.latitude,
    required this.longitude,
  });

  factory CountryCatalogEntry.fromJson(Map<String, dynamic> json) {
    return CountryCatalogEntry(
      countryName: (json['countryName'] ?? '').toString().trim(),
      capitalName: (json['capitalName'] ?? '').toString().trim(),
      continent: (json['continent'] ?? '').toString().trim(),
      alpha2: (json['alpha2'] ?? '').toString().trim().toUpperCase(),
      latitude: _extractDouble(json['latitude']),
      longitude: _extractDouble(json['longitude']),
    );
  }

  DictionaryModel toDictionaryModel() {
    return DictionaryModel(
      countryName: countryName,
      capitalName: capitalName,
      continent: continent,
    );
  }

  MapLatLng? get countryLatLng {
    if (latitude == null || longitude == null) return null;
    return MapLatLng(latitude!, longitude!);
  }

  String get flagEmoji {
    return CountryCatalogService.flagEmojiFromAlpha2(alpha2) ?? '🏳️';
  }

  static double? _extractDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw == null) return null;
    return double.tryParse(raw.toString().trim());
  }
}

class CountryCatalogService {
  static const String _assetPath = 'assets/countries/country_catalog.json';

  static List<CountryCatalogEntry>? _cachedEntries;
  static Map<String, CountryCatalogEntry>? _cachedByAlpha2;
  static Map<String, CountryCatalogEntry>? _cachedByName;
  static Future<List<CountryCatalogEntry>>? _cachedLoadFuture;

  Future<List<CountryCatalogEntry>> preload() => _loadEntries();

  Future<List<DictionaryModel>> loadDictionaryModels() async {
    final entries = await _loadEntries();
    return entries
        .map((entry) => entry.toDictionaryModel())
        .toList(growable: false);
  }

  Future<CountryCatalogEntry?> findByCountryName(String countryName) async {
    await _loadEntries();
    return lookupByCountryName(countryName);
  }

  Future<CountryCatalogEntry?> findByAlpha2(String alpha2) async {
    await _loadEntries();
    return lookupByAlpha2(alpha2);
  }

  CountryCatalogEntry? lookupByCountryName(String countryName) {
    final cached = _cachedByName;
    if (cached == null) return null;
    return cached[normalizeName(countryName)];
  }

  CountryCatalogEntry? lookupByAlpha2(String alpha2) {
    final cached = _cachedByAlpha2;
    if (cached == null) return null;
    return cached[alpha2.trim().toUpperCase()];
  }

  String? alpha2ForCountryName(String countryName) {
    return lookupByCountryName(countryName)?.alpha2;
  }

  String? flagEmojiForCountryName(String countryName) {
    return lookupByCountryName(countryName)?.flagEmoji;
  }

  static String? flagEmojiFromAlpha2(String alpha2) {
    final code = alpha2.trim().toUpperCase();
    if (code.length != 2) return null;

    final first = code.codeUnitAt(0);
    final second = code.codeUnitAt(1);
    if (first < 65 || first > 90 || second < 65 || second > 90) {
      return null;
    }

    final firstFlag = String.fromCharCode(0x1F1E6 + first - 65);
    final secondFlag = String.fromCharCode(0x1F1E6 + second - 65);
    return '$firstFlag$secondFlag';
  }

  static String normalizeName(String value) {
    var v = value.trim();
    if (v.isEmpty) return '';

    v = v.replaceAll('İ', 'i').replaceAll('I', 'i');
    v = v.toLowerCase();

    v = v
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');

    v = v
        .replaceAll('â', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('å', 'a')
        .replaceAll('æ', 'ae')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ñ', 'n')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ø', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ÿ', 'y');

    v = v.replaceAll(RegExp(r"[^\p{L}\p{N}\s]", unicode: true), ' ');
    v = v.replaceAll(RegExp(r'\s+', unicode: true), ' ').trim();
    return v;
  }

  Future<List<CountryCatalogEntry>> _loadEntries() async {
    final cachedEntries = _cachedEntries;
    if (cachedEntries != null) {
      return cachedEntries;
    }

    final inflight = _cachedLoadFuture;
    if (inflight != null) return inflight;

    final future = (() async {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Country catalog asset format is invalid.');
      }

      final entries = decoded
          .whereType<Map>()
          .map((item) => CountryCatalogEntry.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((entry) => entry.countryName.isNotEmpty)
          .toList(growable: false);

      _cachedEntries = entries;
      _cachedByAlpha2 = <String, CountryCatalogEntry>{
        for (final entry in entries)
          if (entry.alpha2.isNotEmpty) entry.alpha2.toUpperCase(): entry,
      };
      _cachedByName = <String, CountryCatalogEntry>{
        for (final entry in entries) normalizeName(entry.countryName): entry,
      };

      return entries;
    })();

    _cachedLoadFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_cachedLoadFuture, future)) {
        _cachedLoadFuture = null;
      }
    }
  }
}
