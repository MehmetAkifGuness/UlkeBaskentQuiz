import 'package:flutter/material.dart';

import '../models/dictionary_model.dart';
import '../models/map_country_model.dart';
import '../services/country_match_service.dart';
import '../services/game_service.dart';
import '../services/iso_country_service.dart';
import '../utils/error_message_utils.dart';

part 'world_map_provider/helpers.dart';

class WorldMapProvider with ChangeNotifier {
  // ADIM 2: Harita ekranı hem GeoJSON verisi, hem de backend/uygulama ülke listesiyle
  // eşleşme yapacağı için loading/error state'lerini burada topluyoruz.
  bool isLoading = false;
  String? errorMessage;

  /// Haritada seçilen ülkenin ISO kodu (veya fallback olarak ülke adı).
  ///
  /// İleride:
  /// - "Hedef ülke" animasyonu
  /// - Multiplayer senaryosunda server tarafından seçilen hedefler
  String? selectedIsoCode;

  /// Uygulama verileriyle eşleştirilmiş seçili ülke (öğrenme modu için asıl model).
  MapCountryModel? selectedCountry;

  /// Backend veya mevcut servislerden alınan ülke listesi.
  List<MapCountryModel> availableCountries = <MapCountryModel>[];

  /// Eşleştirme için ülke verisi hazır mı?
  bool isMapDataReady = false;

  /// Fetih modunda: ülkeyi ilk bilen oyuncunun rengine boyamak için temel altyapı.
  final Map<String, Color> conqueredCountryColors = {};

  /// İleride kıta kıta oyun/öğrenme senaryoları için.
  String selectedContinentFilter = 'ALL';

  final GameService _gameService = GameService();

  Future<void> loadAvailableCountries() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final List<DictionaryModel> dictionary = await _gameService.getDictionary(
        '',
      );

      // ISO çeviri tablosunu hazırla (asset'ten okur). Hata olursa isim bazlı devam eder.
      try {
        await IsoCountryService.ensureLoaded();
      } catch (_) {}

      availableCountries = dictionary
          .map(
            (item) => MapCountryModel(
              // Backend şu an ISO vermiyor; eşleştirme ağırlıkla isim üzerinden yapılacak.
              // ISO eşleşmesi gerektiğinde map-properties'ten bulunan ISO tercih edilir.
              isoCode: IsoCountryService.iso3FromTurkishName(item.countryName) ??
                  item.countryName.trim(),
              name: item.countryName.trim(),
              capital: item.capitalName.trim(),
              continent: _toEnglishContinent(item.continent),
              extra: const <String, dynamic>{'source': 'dictionary'},
            ),
          )
          .toList(growable: false);

      isMapDataReady = true;
      errorMessage = null;
    } catch (e) {
      availableCountries = const <MapCountryModel>[];
      isMapDataReady = false;
      errorMessage = errorMessageFrom(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }

    // TODO: Country detail endpoint ile entegre edilecek.
  }

  Future<void> selectCountryFromMapProperties(
    Map<String, dynamic> properties,
  ) async {
    errorMessage = null;

    final iso = _readFirstNonEmpty(properties, const [
      'ISO3166-1-Alpha-3',
      'ISO3166-1-Alpha-2',
      'iso_a3',
      'ISO_A3',
      'ADM0_A3',
      'adm0_a3',
      'iso_a2',
      'ISO_A2',
      'id',
    ]);

    final name = _readFirstNonEmpty(properties, const [
      'name',
      'NAME',
      'admin',
      'ADMIN',
    ]);

    final mapIsoOrName = (iso ?? name)?.trim();
    if (mapIsoOrName == null || mapIsoOrName.isEmpty) {
      errorMessage = 'Ülke bilgisi okunamadı.';
      selectedCountry = null;
      notifyListeners();
      return;
    }

    // Harita tarafında seçim highlight'ı için bu değeri tutuyoruz.
    selectedIsoCode = mapIsoOrName;

    if (!isMapDataReady) {
      errorMessage = 'Ülke verileri henüz hazır değil.';
      selectedCountry = null;
      notifyListeners();
      return;
    }

    final matched = findCountryByIsoOrName(isoCode: iso, name: name);
    if (matched == null) {
      // UI'da uzun JSON göstermiyoruz; debug amaçlı gerektiğinde burada kullanılabilir.
      // debugPrint('Map properties (unmatched): $properties');
      errorMessage = 'Bu bölge sözlük verilerinde bulunamadı.';
      selectedCountry = null;
      notifyListeners();
      return;
    }

    // Kıta filtresi (varsa) sadece uygulama verisindeki kıta bilgisine göre işletilir.
    final hasContinent = availableCountries.any(
      (c) => (c.continent ?? '').trim().isNotEmpty,
    );

    if (!hasContinent && selectedContinentFilter != 'ALL') {
      // Filtreyi pasif kabul et ama kullanıcıyı bilgilendir.
      errorMessage =
          'Kıta filtresi için ülke verilerinde kıta bilgisi bulunmalı.';
    } else if (hasContinent &&
        selectedContinentFilter != 'ALL' &&
        !isCountryVisibleForCurrentContinent(matched)) {
      // Seçimi iptal et ve highlight'ı kaldır.
      selectedIsoCode = null;
      selectedCountry = null;
      errorMessage = 'Bu ülke seçili kıta filtresinin dışında.';
      notifyListeners();
      return;
    }

    // Harita ISO kodu (varsa) ekranda onu göstermek için match üzerine yaz.
    selectedCountry = MapCountryModel(
      isoCode: (iso != null && iso.trim().isNotEmpty) ? iso.trim() : matched.isoCode,
      name: matched.name,
      continent: matched.continent,
      capital: matched.capital,
      flagUrl: matched.flagUrl,
      extra: matched.extra,
    );

    notifyListeners();
  }

  MapCountryModel? findCountryByIsoOrName({String? isoCode, String? name}) {
    if (availableCountries.isEmpty) return null;
    final matcher = CountryMatchService(availableCountries: availableCountries);

    if (isoCode != null && isoCode.trim().isNotEmpty) {
      final byIso = matcher.matchByIsoCode(isoCode);
      if (byIso != null) return byIso;
    }

    if (name != null && name.trim().isNotEmpty) {
      final byName = matcher.matchByName(name);
      if (byName != null) return byName;
    }

    return null;
  }

  bool isCountryVisibleForCurrentContinent(MapCountryModel country) {
    if (selectedContinentFilter == 'ALL') return true;
    final continent = (country.continent ?? '').trim();
    if (continent.isEmpty) return true; // Kıta bilgisi yoksa engellemiyoruz.
    return continent == selectedContinentFilter;
  }

  void selectCountry(String isoCode) {
    selectedIsoCode = isoCode;
    notifyListeners();
  }

  void clearSelection() {
    selectedIsoCode = null;
    selectedCountry = null;
    notifyListeners();
  }

  void setContinentFilter(String continent) {
    // Kıta bilgisi yoksa filtreyi pasif tutuyoruz.
    final hasContinent = availableCountries.any(
      (c) => (c.continent ?? '').trim().isNotEmpty,
    );

    if (!hasContinent && continent != 'ALL') {
      selectedContinentFilter = 'ALL';
      errorMessage =
          'Kıta filtresi için ülke verilerinde kıta bilgisi bulunmalı.';
      notifyListeners();
      return;
    }

    selectedContinentFilter = continent;

    // Filtre değişince mevcut seçimi yeniden doğrula.
    final current = selectedCountry;
    if (current != null &&
        selectedContinentFilter != 'ALL' &&
        !isCountryVisibleForCurrentContinent(current)) {
      selectedIsoCode = null;
      selectedCountry = null;
    }

    notifyListeners();
  }

  void setCountryColor(String isoCode, Color color) {
    conqueredCountryColors[isoCode] = color;
    notifyListeners();
  }

  void resetConqueredCountries() {
    conqueredCountryColors.clear();
    notifyListeners();
  }
}
