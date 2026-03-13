class DictionaryModel {
  final String countryName;
  final String capitalName;
  final String? continent;

  DictionaryModel({
    required this.countryName,
    required this.capitalName,
    this.continent,
  });

  factory DictionaryModel.fromJson(Map<String, dynamic> json) {
    return DictionaryModel(
      countryName: json['countryName'],
      capitalName: json['capitalName'],
      continent: json['continent'],
    );
  }
}
