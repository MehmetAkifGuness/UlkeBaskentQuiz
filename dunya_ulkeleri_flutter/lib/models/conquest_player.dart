import 'package:flutter/material.dart';

import 'bot_difficulty.dart';

/// Fetih modunda oyuncu modeli (insan/bot).
///
/// Not: İleride multiplayer için de kullanılacak.
class ConquestPlayer {
  static const int initialLives = 3;

  final String id;
  final String name;
  final Color color;
  final bool isBot;
  final BotDifficulty? difficulty;

  int score;
  int conqueredCount;
  int remainingLives;

  ConquestPlayer._({
    required this.id,
    required this.name,
    required this.color,
    required this.isBot,
    required this.difficulty,
    required this.score,
    required this.conqueredCount,
    required this.remainingLives,
  });

  factory ConquestPlayer.human({
    required String id,
    required String name,
    required Color color,
  }) {
    return ConquestPlayer._(
      id: id,
      name: name,
      color: color,
      isBot: false,
      difficulty: null,
      score: 0,
      conqueredCount: 0,
      remainingLives: initialLives,
    );
  }

  factory ConquestPlayer.bot({
    required String id,
    required String name,
    required Color color,
    required BotDifficulty difficulty,
  }) {
    return ConquestPlayer._(
      id: id,
      name: name,
      color: color,
      isBot: true,
      difficulty: difficulty,
      score: 0,
      conqueredCount: 0,
      remainingLives: initialLives,
    );
  }
}

