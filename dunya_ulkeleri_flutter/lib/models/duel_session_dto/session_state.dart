part of '../duel_session_dto.dart';

class DuelSessionState {
  final String? sessionId;
  final String? roomCode;
  final String? status;
  final String? category;
  final String? mode;
  final bool quickMatch;
  final String? lastEventMessage;
  final String? winnerUsername;
  final bool finished;
  final List<DuelPlayerState> players;
  final DuelRoundState? currentRound;

  DuelSessionState({
    required this.sessionId,
    required this.roomCode,
    required this.status,
    required this.category,
    required this.mode,
    required this.quickMatch,
    required this.lastEventMessage,
    required this.winnerUsername,
    required this.finished,
    required this.players,
    required this.currentRound,
  });

  factory DuelSessionState.fromJson(Map<String, dynamic> json) {
    final rawPlayers = json['players'];
    final List<DuelPlayerState> players = (rawPlayers is List)
        ? rawPlayers
            .whereType<Map>()
            .map((e) => DuelPlayerState.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <DuelPlayerState>[];

    DuelRoundState? currentRound;
    final rawRound = json['currentRound'];
    if (rawRound is Map) {
      currentRound = DuelRoundState.fromJson(Map<String, dynamic>.from(rawRound));
    }

    return DuelSessionState(
      sessionId: json['sessionId']?.toString(),
      roomCode: json['roomCode']?.toString(),
      status: json['status']?.toString(),
      category: json['category']?.toString(),
      mode: json['mode']?.toString(),
      quickMatch: (json['quickMatch'] ?? false) as bool,
      lastEventMessage: json['lastEventMessage']?.toString(),
      winnerUsername: json['winnerUsername']?.toString(),
      finished: (json['finished'] ?? false) as bool,
      players: players,
      currentRound: currentRound,
    );
  }
}

class DuelPlayerState {
  final String? playerId;
  final String? username;
  final int score;
  final bool connected;

  DuelPlayerState({
    required this.playerId,
    required this.username,
    required this.score,
    required this.connected,
  });

  factory DuelPlayerState.fromJson(Map<String, dynamic> json) {
    return DuelPlayerState(
      playerId: json['playerId']?.toString(),
      username: json['username']?.toString(),
      score: ((json['score'] ?? 0) as num).toInt(),
      connected: (json['connected'] ?? false) as bool,
    );
  }
}

class DuelRoundState {
  final int roundNumber;
  final String? questionText;
  final List<String> options;
  final bool locked;
  final String? winnerPlayerId;
  final DateTime? startedAt;
  final DateTime? deadlineAt;
  final String? correctAnswer;

  DuelRoundState({
    required this.roundNumber,
    required this.questionText,
    required this.options,
    required this.locked,
    required this.winnerPlayerId,
    required this.startedAt,
    required this.deadlineAt,
    required this.correctAnswer,
  });

  factory DuelRoundState.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = (rawOptions is List)
        ? rawOptions.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    return DuelRoundState(
      roundNumber: ((json['roundNumber'] ?? 0) as num).toInt(),
      questionText: json['questionText']?.toString(),
      options: options,
      locked: (json['locked'] ?? false) as bool,
      winnerPlayerId: json['winnerPlayerId']?.toString(),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      deadlineAt: json['deadlineAt'] != null
          ? DateTime.tryParse(json['deadlineAt'].toString())
          : null,
      correctAnswer: json['correctAnswer']?.toString(),
    );
  }
}

