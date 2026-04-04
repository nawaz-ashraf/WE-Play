import 'package:shared_preferences/shared_preferences.dart';

class EndlessGameStats {
  final int highScore;
  final int totalPlays;
  final int totalCoinsEarned;
  final int lastScore;

  const EndlessGameStats({
    required this.highScore,
    required this.totalPlays,
    required this.totalCoinsEarned,
    required this.lastScore,
  });
}

class EndlessGameStatsStorage {
  EndlessGameStatsStorage(this._prefs);

  final SharedPreferences _prefs;

  String _key(String gameId, String suffix) => 'endless_${gameId}_$suffix';

  EndlessGameStats read(String gameId) {
    return EndlessGameStats(
      highScore: _prefs.getInt(_key(gameId, 'high_score')) ?? 0,
      totalPlays: _prefs.getInt(_key(gameId, 'total_plays')) ?? 0,
      totalCoinsEarned: _prefs.getInt(_key(gameId, 'total_coins')) ?? 0,
      lastScore: _prefs.getInt(_key(gameId, 'last_score')) ?? 0,
    );
  }

  bool saveRun({
    required String gameId,
    required int score,
    required int coinsEarned,
  }) {
    final current = read(gameId);
    final newHighScore = score > current.highScore ? score : current.highScore;

    _prefs.setInt(_key(gameId, 'high_score'), newHighScore);
    _prefs.setInt(_key(gameId, 'total_plays'), current.totalPlays + 1);
    _prefs.setInt(
      _key(gameId, 'total_coins'),
      current.totalCoinsEarned + coinsEarned,
    );
    _prefs.setInt(_key(gameId, 'last_score'), score);

    return score > current.highScore;
  }
}
