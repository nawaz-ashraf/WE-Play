import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub authentication service — will integrate Firebase Auth
class AuthService {
  /// Sign in anonymously
  Future<String> signInAnonymously() async {
    // TODO: Implement Firebase anonymous auth
    await Future.delayed(const Duration(milliseconds: 500));
    return 'demo_user';
  }

  /// Sign in with Google
  Future<String> signInWithGoogle() async {
    // TODO: Implement Google Sign-In + Firebase
    await Future.delayed(const Duration(milliseconds: 500));
    return 'demo_user';
  }

  /// Sign out
  Future<void> signOut() async {
    // TODO: Implement Firebase sign out
  }

  /// Get current user ID
  String? get currentUserId => 'demo_user';

  /// Check if user is signed in
  bool get isSignedIn => true;
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
