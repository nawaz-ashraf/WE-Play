import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────
//  COIN SERVICE
//  Call awardCoins() from GlowMergeNotifier
//  or from the score screen after each session.
// ─────────────────────────────────────────────
class CoinService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Award coins to the current user.
  /// Also submits score to leaderboard if it's a new high score.
  Future<void> awardCoins(int amount) async {
    if (_uid == null || amount <= 0) return;
    await _db.doc('users/$_uid').set(
      {'coins': FieldValue.increment(amount)},
      SetOptions(merge: true),
    );
  }

  Future<void> submitScore({
    required String gameId,
    required int score,
    required String username,
    required String avatarUrl,
  }) async {
    if (_uid == null) return;

    final userRef = _db.doc('users/$_uid');
    final snap    = await userRef.get();
    final data    = snap.data() ?? {};
    final current = (data['highScores'] as Map?)?.containsKey(gameId) == true
        ? (data['highScores'][gameId] as num).toInt()
        : 0;

    if (score <= current) return;

    // Update local high score
    await userRef.set({
      'highScores': {gameId: score}
    }, SetOptions(merge: true));

    // Push to leaderboard
    final week = _weekId();
    await _db
        .collection('leaderboards/$gameId/scores')
        .add({
      'uid':       _uid,
      'username':  username,
      'avatarUrl': avatarUrl,
      'score':     score,
      'timestamp': FieldValue.serverTimestamp(),
      'weekOf':    week,
    });
  }

  String _weekId() {
    final now  = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return '${monday.year}-W${_weekNumber(now).toString().padLeft(2, '0')}';
  }

  int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday == 1
        ? startOfYear
        : startOfYear.add(Duration(days: 8 - startOfYear.weekday));
    if (date.isBefore(firstMonday)) return 1;
    return ((date.difference(firstMonday).inDays) ~/ 7) + 1;
  }
}
