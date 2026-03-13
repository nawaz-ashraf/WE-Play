import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub AdMob service — will integrate google_mobile_ads
class AdService {
  int _sessionCount = 0;

  /// Initialize ad SDKs
  Future<void> initialize() async {
    // TODO: Initialize MobileAds.instance
  }

  /// Show interstitial ad (every 3rd session)
  Future<void> showInterstitialIfReady() async {
    _sessionCount++;
    if (_sessionCount % 3 == 0) {
      // TODO: Show interstitial ad
    }
  }

  /// Show rewarded ad for coins
  Future<bool> showRewardedAd() async {
    // TODO: Load and show rewarded ad, return true if completed
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Simulate ad watched
  }

  /// Dispose ads
  void dispose() {
    // TODO: Dispose ad instances
  }
}

final adServiceProvider = Provider<AdService>((ref) => AdService());
