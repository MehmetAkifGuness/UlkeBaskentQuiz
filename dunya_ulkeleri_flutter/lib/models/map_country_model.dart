class MapCountryModel {
  /// ISO 3166-1 Alpha-3 (tercihen) veya GeoJSON'dan gelen benzersiz ülke anahtarı.
  ///
  /// Not: Bazı GeoJSON kaynaklarında ISO kodu bulunmayabilir. Bu durumda geçici
  /// olarak ülke adı/id alanı isoCode yerine yazılabilir (ADIM 1 için yeterli).
  final String isoCode;
  final String name;
  final String? continent;
  final String? capital;
  final String? flagUrl;
  final Map<String, dynamic>? extra;

  const MapCountryModel({
    required this.isoCode,
    required this.name,
    this.continent,
    this.capital,
    this.flagUrl,
    this.extra,
  });

  factory MapCountryModel.fromJson(Map<String, dynamic> json) {
    final extraValue = json['extra'];
    return MapCountryModel(
      isoCode: (json['isoCode'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      continent: json['continent']?.toString(),
      capital: json['capital']?.toString(),
      flagUrl: json['flagUrl']?.toString(),
      extra: extraValue is Map ? Map<String, dynamic>.from(extraValue) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isoCode': isoCode,
      'name': name,
      'continent': continent,
      'capital': capital,
      'flagUrl': flagUrl,
      'extra': extra,
    };
  }
}

