import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:we_play/core/models/user_model.dart';

/// Stub Firestore service — will integrate Cloud Firestore
class FirestoreService {
  /// Get user profile
  Future<UserModel> getUser(String uid) async {
    // TODO: Implement Firestore fetch
    return UserModel.demo();
  }

  /// Update user profile
  Future<void> updateUser(UserModel user) async {
    // TODO: Implement Firestore update
  }

  /// Save game score
  Future<void> saveScore({
    required String gameId,
    required String uid,
    required String username,
    required int score,
  }) async {
    // TODO: Implement Firestore score save
  }

  /// Get leaderboard for a game
  Future<List<Map<String, dynamic>>> getLeaderboard(String gameId,
      {int limit = 100}) async {
    // TODO: Implement Firestore leaderboard query
    return [];
  }
}

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());
