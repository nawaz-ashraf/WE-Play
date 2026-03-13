import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Leaderboard management service
class LeaderboardService {
  /// Submit score to leaderboard
  Future<void> submitScore({
    required String gameId,
    required String uid,
    required String username,
    required int score,
  }) async {
    // TODO: Save to Firestore leaderboards/{gameId}/scores
  }

  /// Get top scores for a game
  Future<List<LeaderboardEntry>> getTopScores(String gameId,
      {int limit = 100}) async {
    // TODO: Fetch from Firestore
    return _demoLeaderboard;
  }

  /// Get user's rank for a specific game
  Future<int?> getUserRank(String gameId, String uid) async {
    // TODO: Query Firestore for rank
    return 42;
  }
}

class LeaderboardEntry {
  final String uid;
  final String username;
  final int score;
  final int rank;
  final String avatarUrl;

  const LeaderboardEntry({
    required this.uid,
    required this.username,
    required this.score,
    required this.rank,
    this.avatarUrl = '',
  });
}

final _demoLeaderboard = [
  const LeaderboardEntry(
      uid: '1', username: 'xXblaze99Xx', score: 28400, rank: 1),
  const LeaderboardEntry(
      uid: '2', username: 'neon_queen', score: 24100, rank: 2),
  const LeaderboardEntry(uid: '3', username: 'sk8r_boi', score: 21800, rank: 3),
  const LeaderboardEntry(
      uid: '4', username: 'vibes.only', score: 19200, rank: 4),
  const LeaderboardEntry(uid: '5', username: 'ghostt_', score: 17500, rank: 5),
];

final leaderboardServiceProvider =
    Provider<LeaderboardService>((ref) => LeaderboardService());
