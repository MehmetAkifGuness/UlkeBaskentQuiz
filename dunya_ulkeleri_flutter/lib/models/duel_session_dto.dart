// lib/models/duel_session_dto.dart

part 'duel_session_dto/session_state.dart';

class CreateDuelSessionRequest {
  final String category;
  final String mode;

  CreateDuelSessionRequest({
    required this.category,
    required this.mode,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'mode': mode,
      };
}

class CreateDuelSessionResponse {
  final String sessionId;
  final String roomCode;
  final String playerId;

  CreateDuelSessionResponse({
    required this.sessionId,
    required this.roomCode,
    required this.playerId,
  });

  factory CreateDuelSessionResponse.fromJson(Map<String, dynamic> json) {
    return CreateDuelSessionResponse(
      sessionId: (json['sessionId'] ?? '').toString(),
      roomCode: (json['roomCode'] ?? '').toString(),
      playerId: (json['playerId'] ?? '').toString(),
    );
  }
}

class JoinDuelSessionRequest {
  const JoinDuelSessionRequest();

  Map<String, dynamic> toJson() => const <String, dynamic>{};
}

class JoinDuelSessionResponse {
  final String sessionId;
  final String roomCode;
  final String playerId;

  JoinDuelSessionResponse({
    required this.sessionId,
    required this.roomCode,
    required this.playerId,
  });

  factory JoinDuelSessionResponse.fromJson(Map<String, dynamic> json) {
    return JoinDuelSessionResponse(
      sessionId: (json['sessionId'] ?? '').toString(),
      roomCode: (json['roomCode'] ?? '').toString(),
      playerId: (json['playerId'] ?? '').toString(),
    );
  }
}

class SubmitDuelAnswerRequest {
  final String sessionId;
  final String playerId;
  final String selectedOption;

  SubmitDuelAnswerRequest({
    required this.sessionId,
    required this.playerId,
    required this.selectedOption,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'playerId': playerId,
        'selectedOption': selectedOption,
      };
}

class LeaveDuelSessionRequest {
  final String sessionId;
  final String playerId;

  LeaveDuelSessionRequest({
    required this.sessionId,
    required this.playerId,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'playerId': playerId,
      };
}

