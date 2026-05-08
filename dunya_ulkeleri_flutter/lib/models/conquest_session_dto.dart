// lib/models/conquest_session_dto.dart

class CreateConquestSessionRequest {
  final String username;
  final String colorHex;
  final String continentFilter;

  CreateConquestSessionRequest({
    required this.username,
    required this.colorHex,
    required this.continentFilter,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'colorHex': colorHex,
        'continentFilter': continentFilter,
      };
}

class CreateConquestSessionResponse {
  final String sessionId;
  final String roomCode;
  final String playerId;

  CreateConquestSessionResponse({
    required this.sessionId,
    required this.roomCode,
    required this.playerId,
  });

  factory CreateConquestSessionResponse.fromJson(Map<String, dynamic> json) {
    return CreateConquestSessionResponse(
      sessionId: (json['sessionId'] ?? '').toString(),
      roomCode: (json['roomCode'] ?? '').toString(),
      playerId: (json['playerId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'roomCode': roomCode,
        'playerId': playerId,
      };
}

class JoinConquestSessionRequest {
  final String username;
  final String colorHex;

  JoinConquestSessionRequest({
    required this.username,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'colorHex': colorHex,
      };
}

class JoinConquestSessionResponse {
  final String sessionId;
  final String roomCode;
  final String playerId;

  JoinConquestSessionResponse({
    required this.sessionId,
    required this.roomCode,
    required this.playerId,
  });

  factory JoinConquestSessionResponse.fromJson(Map<String, dynamic> json) {
    return JoinConquestSessionResponse(
      sessionId: (json['sessionId'] ?? '').toString(),
      roomCode: (json['roomCode'] ?? '').toString(),
      playerId: (json['playerId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'roomCode': roomCode,
        'playerId': playerId,
      };
}

class StartConquestGameRequest {
  final String sessionId;
  final String playerId;

  StartConquestGameRequest({
    required this.sessionId,
    required this.playerId,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'playerId': playerId,
      };
}

class SubmitConquestAnswerRequest {
  final String sessionId;
  final String playerId;
  final String selectedIsoCode;
  final String selectedCountryName;

  SubmitConquestAnswerRequest({
    required this.sessionId,
    required this.playerId,
    required this.selectedIsoCode,
    required this.selectedCountryName,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'playerId': playerId,
        'selectedIsoCode': selectedIsoCode,
        'selectedCountryName': selectedCountryName,
      };
}

class ConquestPlayerState {
  final String? playerId;
  final String? username;
  final String? colorHex;
  final String? type;
  final int score;
  final int conqueredCount;
  final bool connected;

  ConquestPlayerState({
    required this.playerId,
    required this.username,
    required this.colorHex,
    required this.type,
    required this.score,
    required this.conqueredCount,
    required this.connected,
  });

  factory ConquestPlayerState.fromJson(Map<String, dynamic> json) {
    return ConquestPlayerState(
      playerId: json['playerId']?.toString(),
      username: json['username']?.toString(),
      colorHex: json['colorHex']?.toString(),
      type: json['type']?.toString(),
      score: ((json['score'] ?? 0) as num).toInt(),
      conqueredCount: ((json['conqueredCount'] ?? 0) as num).toInt(),
      connected: (json['connected'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'username': username,
        'colorHex': colorHex,
        'type': type,
        'score': score,
        'conqueredCount': conqueredCount,
        'connected': connected,
      };
}

class ConquestRoundState {
  final int roundNumber;
  final String? targetIsoCode;
  final String? targetCountryName;
  final bool locked;
  final String? winnerPlayerId;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  ConquestRoundState({
    required this.roundNumber,
    required this.targetIsoCode,
    required this.targetCountryName,
    required this.locked,
    required this.winnerPlayerId,
    required this.startedAt,
    required this.finishedAt,
  });

  factory ConquestRoundState.fromJson(Map<String, dynamic> json) {
    return ConquestRoundState(
      roundNumber: ((json['roundNumber'] ?? 0) as num).toInt(),
      targetIsoCode: json['targetIsoCode']?.toString(),
      targetCountryName: json['targetCountryName']?.toString(),
      locked: (json['locked'] ?? false) as bool,
      winnerPlayerId: json['winnerPlayerId']?.toString(),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.tryParse(json['finishedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'targetIsoCode': targetIsoCode,
        'targetCountryName': targetCountryName,
        'locked': locked,
        'winnerPlayerId': winnerPlayerId,
        'startedAt': startedAt?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
      };
}

class ConquestSessionState {
  final String? sessionId;
  final String? roomCode;
  final String? status;
  final String? selectedContinentFilter;
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
      players: playersJson
          .whereType<Map>()
          .map((item) => ConquestPlayerState.fromJson(
                Map<String, dynamic>.from(item),
              ))
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
        'players': players.map((e) => e.toJson()).toList(),
        'conqueredCountryColors': conqueredCountryColors,
        'currentRound': currentRound?.toJson(),
        'playableIsoCodes': playableIsoCodes,
        'lastEventMessage': lastEventMessage,
        'lastWinnerPlayerId': lastWinnerPlayerId,
        'roundLocked': roundLocked,
      };
}
