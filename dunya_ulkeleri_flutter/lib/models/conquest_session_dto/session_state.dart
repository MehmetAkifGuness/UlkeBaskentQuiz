part of '../conquest_session_dto.dart';

class ConquestSessionState {
  final String? sessionId;
  final String? roomCode;
  final String? status;
  final String? selectedContinentFilter;
  final String? hostPlayerId;
  final bool quickMatch;
  final List<ConquestPlayerState> players;
  final Map<String, String> conqueredCountryColors;
  final ConquestRoundState? currentRound;
  final List<String> playableIsoCodes;
  final String? lastEventMessage;
  final String? lastWinnerPlayerId;
  final bool roundLocked;

  ConquestSessionState({
    required this.sessionId,
    required this.roomCode,
    required this.status,
    required this.selectedContinentFilter,
    required this.hostPlayerId,
    required this.quickMatch,
    required this.players,
    required this.conqueredCountryColors,
    required this.currentRound,
    required this.playableIsoCodes,
    required this.lastEventMessage,
    required this.lastWinnerPlayerId,
    required this.roundLocked,
  });

  factory ConquestSessionState.fromJson(Map<String, dynamic> json) {
    final playersJson = (json['players'] as List?) ?? const [];

    final conqueredColorsRaw =
        (json['conqueredCountryColors'] as Map?) ?? const {};
    final conqueredColors = conqueredColorsRaw.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );

    final playableIsoCodesJson = (json['playableIsoCodes'] as List?) ?? const [];

    return ConquestSessionState(
      sessionId: json['sessionId']?.toString(),
      roomCode: json['roomCode']?.toString(),
      status: json['status']?.toString(),
      selectedContinentFilter: json['selectedContinentFilter']?.toString(),
      hostPlayerId: json['hostPlayerId']?.toString(),
      quickMatch: (json['quickMatch'] ?? false) as bool,
      players: playersJson
          .whereType<Map>()
          .map(
            (item) => ConquestPlayerState.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      conqueredCountryColors: Map<String, String>.from(conqueredColors),
      currentRound: json['currentRound'] != null
          ? ConquestRoundState.fromJson(
              Map<String, dynamic>.from(json['currentRound']),
            )
          : null,
      playableIsoCodes: playableIsoCodesJson.map((e) => e.toString()).toList(),
      lastEventMessage: json['lastEventMessage']?.toString(),
      lastWinnerPlayerId: json['lastWinnerPlayerId']?.toString(),
      roundLocked: (json['roundLocked'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'roomCode': roomCode,
        'status': status,
        'selectedContinentFilter': selectedContinentFilter,
        'hostPlayerId': hostPlayerId,
        'quickMatch': quickMatch,
        'players': players.map((e) => e.toJson()).toList(),
        'conqueredCountryColors': conqueredCountryColors,
        'currentRound': currentRound?.toJson(),
        'playableIsoCodes': playableIsoCodes,
        'lastEventMessage': lastEventMessage,
        'lastWinnerPlayerId': lastWinnerPlayerId,
        'roundLocked': roundLocked,
      };
}
