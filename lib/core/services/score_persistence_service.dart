import 'package:shared_preferences/shared_preferences.dart';

/// Centralised best-score persistence using SharedPreferences.
///
/// Each game's best score is stored under the key `best_score_{gameId}`.
/// Scores are only overwritten when the new value exceeds the current one.
class ScorePersistenceService {
  static const String _prefPrefix = 'best_score_';

  // ── SAVE ──────────────────────────────────────
  Future<void> saveBestScore(String gameId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefPrefix$gameId';
    final current = prefs.getInt(key) ?? 0;
    if (score > current) {
      await prefs.setInt(key, score);
    }
  }

  // ── LOAD ──────────────────────────────────────
  Future<int> loadBestScore(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefPrefix$gameId') ?? 0;
  }

  // ── LOAD ALL ──────────────────────────────────
  Future<Map<String, int>> loadAllBestScores(List<String> gameIds) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, int>{};
    for (final id in gameIds) {
      result[id] = prefs.getInt('$_prefPrefix$id') ?? 0;
    }
    return result;
  }
}
