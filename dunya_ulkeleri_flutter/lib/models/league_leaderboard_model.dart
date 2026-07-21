class LeagueLeaderboardEntry {
  final int rank;
  final String username;
  final int trophies;
  final String league;
  final int avatarId;
  final bool hasCustomAvatar;
  final bool currentUser;

  const LeagueLeaderboardEntry({
    required this.rank,
    required this.username,
    required this.trophies,
    required this.league,
    required this.avatarId,
    required this.hasCustomAvatar,
    required this.currentUser,
  });

  factory LeagueLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeagueLeaderboardEntry(
      rank: ((json['rank'] ?? 0) as num).toInt(),
      username: (json['username'] ?? '').toString(),
      trophies: ((json['trophies'] ?? 0) as num).toInt(),
      league: (json['league'] ?? '').toString(),
      avatarId: ((json['avatarId'] ?? 1) as num).toInt(),
      hasCustomAvatar: json['hasCustomAvatar'] == true,
      currentUser: json['currentUser'] == true,
    );
  }
}

class LeagueLeaderboardModel {
  final int season;
  final int totalPlayers;
  final List<LeagueLeaderboardEntry> topPlayers;
  final LeagueLeaderboardEntry? currentUser;

  const LeagueLeaderboardModel({
    required this.season,
    required this.totalPlayers,
    required this.topPlayers,
    required this.currentUser,
  });

  factory LeagueLeaderboardModel.fromJson(Map<String, dynamic> json) {
    final rawPlayers = json['topPlayers'] as List? ?? const [];
    final currentJson = json['currentUser'];
    return LeagueLeaderboardModel(
      season: ((json['season'] ?? 0) as num).toInt(),
      totalPlayers: ((json['totalPlayers'] ?? 0) as num).toInt(),
      topPlayers: rawPlayers
          .whereType<Map>()
          .map((entry) => LeagueLeaderboardEntry.fromJson(
                Map<String, dynamic>.from(entry),
              ))
          .toList(growable: false),
      currentUser: currentJson is Map
          ? LeagueLeaderboardEntry.fromJson(Map<String, dynamic>.from(currentJson))
          : null,
    );
  }
}
