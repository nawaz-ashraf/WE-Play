/// Represents a single game play session
class GameSession {
  final String gameId;
  final int score;
  final int coinsEarned;
  final int xpEarned;
  final int comboMax;
  final Duration duration;
  final DateTime playedAt;

  GameSession({
    required this.gameId,
    required this.score,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    this.comboMax = 0,
    this.duration = Duration.zero,
    DateTime? playedAt,
  }) : playedAt = playedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'score': score,
        'coinsEarned': coinsEarned,
        'xpEarned': xpEarned,
        'comboMax': comboMax,
        'durationMs': duration.inMilliseconds,
        'playedAt': playedAt.toIso8601String(),
      };

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      gameId: json['gameId'] as String,
      score: json['score'] as int,
      coinsEarned: json['coinsEarned'] as int? ?? 0,
      xpEarned: json['xpEarned'] as int? ?? 0,
      comboMax: json['comboMax'] as int? ?? 0,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      playedAt: json['playedAt'] != null
          ? DateTime.parse(json['playedAt'] as String)
          : DateTime.now(),
    );
  }
}
