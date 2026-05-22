part of '../conquest_multiplayer_provider.dart';

extension ConquestMultiplayerProviderTarget on ConquestMultiplayerProvider {
  /// Online modda backend bazen hedef ülke adını İngilizce gönderebiliyor.
  /// UI tarafında ISO kodundan Türkçe karşılığına çevirip gösteriyoruz.
  String? get currentTargetName {
    final round = sessionState?.currentRound;
    if (round == null) return null;

    final rawName = round.targetCountryName?.trim();
    final rawIso = (round.targetIsoCode ?? '').trim();

    String? trNameFromIso(String iso) {
      final v = iso.trim();
      if (v.isEmpty) return null;

      // ISO3 ise direkt dene; ISO2 ise önce ISO3'e çevir.
      if (v.length == 3) {
        return IsoCountryService.turkishNameFromIso3(v);
      }
      if (v.length == 2) {
        final iso3 = IsoCountryService.iso3FromAlpha2(v);
        if (iso3 != null) return IsoCountryService.turkishNameFromIso3(iso3);
      }
      return null;
    }

    final translated = trNameFromIso(rawIso);
    if (translated != null && translated.trim().isNotEmpty) return translated;

    // ISO gelmiyorsa veya eşleşmezse, backend'in gönderdiği ismi fallback olarak kullan.
    return (rawName == null || rawName.isEmpty) ? null : rawName;
  }
}
