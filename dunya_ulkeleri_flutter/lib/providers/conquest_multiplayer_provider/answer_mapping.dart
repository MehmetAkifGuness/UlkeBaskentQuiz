part of '../conquest_multiplayer_provider.dart';

extension ConquestMultiplayerProviderAnswerMapping on ConquestMultiplayerProvider {
  Future<void> submitOnlineAnswerFromMapProperties(
    Map<String, dynamic> mapProperties,
  ) async {
    final sid = sessionId;
    final pid = playerId;
    if (sid == null || pid == null) {
      errorMessage = 'Cevap göndermek için sessionId/playerId gerekli.';
      _emit();
      return;
    }

    final state = sessionState;
    if (state == null) {
      errorMessage = 'Oturum durumu henüz hazır değil.';
      _emit();
      return;
    }

    try {
      await IsoCountryService.ensureLoaded();
    } catch (_) {}

    String? readFirstNonEmpty(List<String> keys) {
      for (final key in keys) {
        final raw = mapProperties[key];
        final value = raw?.toString().trim();
        if (value != null && value.isNotEmpty && value != '-99') return value;
      }
      return null;
    }

    final isoCandidate = readFirstNonEmpty(const [
      'ISO3166-1-Alpha-2',
      'ISO_A2',
      'iso_a2',
      'ISO3166-1-Alpha-3',
      'ISO_A3',
      'iso_a3',
      'ADM0_A3',
      'adm0_a3',
      'id',
    ]);

    final nameCandidate = readFirstNonEmpty(const [
      'name',
      'NAME',
      'admin',
      'ADMIN',
    ]);

    final available = state.playableIsoCodes.isNotEmpty
        ? state.playableIsoCodes
            .map((iso) => MapCountryModel(isoCode: iso, name: iso))
            .toList(growable: false)
        : <MapCountryModel>[];

    if (available.isEmpty) {
      final fallbackIso = (isoCandidate ?? '').trim();
      final fallbackName = (nameCandidate ?? '').trim();
      if (fallbackIso.isNotEmpty || fallbackName.isNotEmpty) {
        available.add(
          MapCountryModel(
            isoCode: fallbackIso.isNotEmpty ? fallbackIso : fallbackName,
            name: fallbackName.isNotEmpty ? fallbackName : fallbackIso,
          ),
        );
      }
    }

    final matcher = CountryMatchService(availableCountries: available);
    MapCountryModel? matched;

    if (isoCandidate != null && isoCandidate.trim().isNotEmpty) {
      matched = matcher.matchByIsoCode(isoCandidate);
    }
    matched ??= (nameCandidate != null && nameCandidate.trim().isNotEmpty)
        ? matcher.matchByName(nameCandidate)
        : null;

    if (matched == null || matched.isoCode.trim().isEmpty) {
      errorMessage = 'Bu bölge oyun verilerinde yok.';
      _emit();
      return;
    }

    _wsService.submitAnswer(
      SubmitConquestAnswerRequest(
        sessionId: sid,
        playerId: pid,
        selectedIsoCode: matched.isoCode,
        selectedCountryName: nameCandidate ?? matched.name,
      ),
    );
  }
}
