import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clip capture & sharing service
class ClipService {
  /// Capture last 10 seconds of gameplay
  Future<String?> captureClip() async {
    // TODO: Implement screen recording capture
    return null;
  }

  /// Add WE PLAY watermark overlay
  Future<String?> addWatermark(String clipPath, int score) async {
    // TODO: Implement video overlay
    return clipPath;
  }

  /// Upload clip to Firebase Storage
  Future<String?> uploadClip(String uid, String clipPath) async {
    // TODO: Upload to Firebase Storage clips/{uid}/{timestamp}.mp4
    return null;
  }

  /// Share clip via share_plus
  Future<void> shareClip(String clipPath) async {
    // TODO: Use share_plus to share
  }
}

final clipServiceProvider = Provider<ClipService>((ref) => ClipService());
