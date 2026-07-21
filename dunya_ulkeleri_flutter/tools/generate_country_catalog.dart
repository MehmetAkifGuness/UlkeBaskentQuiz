import 'dart:convert';
import 'dart:io';

class _GeoPoint {
  final double longitude;
  final double latitude;

  const _GeoPoint(this.longitude, this.latitude);
}

void main(List<String> args) {
  final root = Directory.current.path;

  final dictionary = _readJsonList(
    '$root/assets/dictionary/dictionary_tr.json',
  );
  final trIso = _readJsonMap(
    '$root/assets/iso/i18n_iso_countries_tr.json',
  );
  final worldMap = _readJsonMap(
    '$root/assets/maps/world_map_simplified.json',
  );

  final normalizedNameToAlpha2 = <String, String>{};
  final countries = trIso['countries'];
  if (countries is Map) {
    for (final entry in countries.entries) {
      final alpha2 = entry.key.toString().trim().toUpperCase();
      if (alpha2.isEmpty) continue;

      void indexValue(String name) {
        final normalized = normalizeName(name);
        if (normalized.isEmpty) return;
        normalizedNameToAlpha2.putIfAbsent(normalized, () => alpha2);
      }

      final value = entry.value;
      if (value is String) {
        indexValue(value);
      } else if (value is List) {
        for (final item in value) {
          if (item is String) indexValue(item);
        }
      }
    }
  }

  final manualAliases = <String, String>{
    'kibris cumhuriyeti': 'CY',
    'bosna hersek': 'BA',
    'belarus beyaz rusya': 'BY',
    'cekya': 'CZ',
    'dogu timor': 'TL',
    'esvatini': 'SZ',
    'filistin': 'PS',
    'kongo cumhuriyeti': 'CG',
    'kongo demokratik cumhuriyeti': 'CD',
    'yesil burun adalari': 'CV',
    'bhutan': 'BT',
    'lesotho': 'LS',
    'myanmar': 'MM',
  };

  final locationByAlpha2 = _buildLocations(worldMap);
  const fallbackLocations = <String, _GeoPoint>{
    'BY': _GeoPoint(27.9534, 53.7098),
    'MM': _GeoPoint(95.9560, 21.9162),
    'FR': _GeoPoint(2.2137, 46.2276),
    'NO': _GeoPoint(8.4689, 60.4720),
  };
  final output = <Map<String, dynamic>>[];
  final missingAlpha2 = <String>[];
  final missingCentroid = <String>[];

  for (final item in dictionary) {
    if (item is! Map) continue;
    final countryName = (item['countryName'] ?? '').toString().trim();
    final capitalName = (item['capitalName'] ?? '').toString().trim();
    final continent = (item['continent'] ?? '').toString().trim();
    if (countryName.isEmpty) continue;

    final normalized = normalizeName(countryName);
    final alpha2 = manualAliases[normalized] ??
        normalizedNameToAlpha2[normalized] ??
        normalizedNameToAlpha2[normalizeName(countryName.replaceAll('-', ' '))];

    if (alpha2 == null || alpha2.isEmpty) {
      missingAlpha2.add(countryName);
      continue;
    }

    final location = locationByAlpha2[alpha2] ?? fallbackLocations[alpha2];
    if (location == null) {
      missingCentroid.add('$countryName ($alpha2)');
    }

    output.add({
      'countryName': countryName,
      'capitalName': capitalName,
      'continent': continent,
      'alpha2': alpha2,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
    });
  }

  output.sort((a, b) {
    return (a['countryName'] as String).compareTo(b['countryName'] as String);
  });

  final outFile = File('$root/assets/countries/country_catalog.json');
  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(jsonEncode(output), flush: true);

  stdout.writeln(
    'Generated ${output.length} country rows at ${outFile.path}',
  );
  if (missingAlpha2.isNotEmpty) {
    stdout.writeln(
      'Missing alpha2 for ${missingAlpha2.length} entries: ${missingAlpha2.join(', ')}',
    );
  }
  if (missingCentroid.isNotEmpty) {
    stdout.writeln(
      'Missing centroid for ${missingCentroid.length} entries: ${missingCentroid.join(', ')}',
    );
  }
}

List<dynamic> _readJsonList(String path) {
  final raw = File(path).readAsStringSync(encoding: utf8);
  final decoded = jsonDecode(raw);
  if (decoded is List) return decoded;
  throw FormatException('Expected JSON list at $path');
}

Map<String, dynamic> _readJsonMap(String path) {
  final raw = File(path).readAsStringSync(encoding: utf8);
  final decoded = jsonDecode(raw);
  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }
  throw FormatException('Expected JSON map at $path');
}

Map<String, _GeoPoint> _buildLocations(Map<String, dynamic> worldMap) {
  final result = <String, _GeoPoint>{};
  final features = worldMap['features'];
  if (features is! List) return result;

  for (final feature in features) {
    if (feature is! Map) continue;
    final properties = feature['properties'];
    final geometry = feature['geometry'];
    if (properties is! Map || geometry is! Map) continue;

    final alpha2 = (properties['ISO3166-1-Alpha-2'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    if (alpha2.length != 2 || alpha2 == '-99') continue;

    final location = _representativePoint(geometry['coordinates']);
    if (location == null) continue;

    result[alpha2] = location;
  }

  return result;
}

_GeoPoint? _representativePoint(dynamic node) {
  var longitudeTotal = 0.0;
  var latitudeTotal = 0.0;
  var pointCount = 0;

  void visit(dynamic current) {
    if (current is! List) return;
    if (current.length == 2 && current[0] is num && current[1] is num) {
      longitudeTotal += (current[0] as num).toDouble();
      latitudeTotal += (current[1] as num).toDouble();
      pointCount++;
      return;
    }
    for (final child in current) {
      visit(child);
    }
  }

  visit(node);
  if (pointCount == 0) return null;
  return _GeoPoint(
    longitudeTotal / pointCount,
    latitudeTotal / pointCount,
  );
}

String normalizeName(String value) {
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
