import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Production-ready AdMob service handling interstitial, rewarded, and banner ads.
///
/// Uses production Android AdMob unit IDs and test iOS IDs.
class AdService {
  final SharedPreferences _prefs;

  // ── Session Tracking ─────────────────────────
  static const _sessionCountKey = 'ad_session_count';
  static const int _sessionThreshold = 3;

  // ── Ad Unit IDs ─────────────────────────────
  static String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-4392358942856616/9054884661'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-4392358942856616/9054884661'
      : 'ca-app-pub-3940256099942544/1712485313';

  static String get _bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-4392358942856616/1367966331'
      : 'ca-app-pub-3940256099942544/2934735716';

  // ── Ad Instances ─────────────────────────────
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;

  AdService(this._prefs);

  // ── Initialization ───────────────────────────

  /// Initialize the Mobile Ads SDK and pre-load ads.
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // ══════════════════════════════════════════════
  //  INTERSTITIAL ADS
  // ══════════════════════════════════════════════

  void _loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd(); // Pre-load next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _isInterstitialLoading = false;
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Called after each completed game session.
  /// Shows an interstitial ad every [_sessionThreshold] sessions.
  Future<void> showInterstitialIfReady() async {
    int count = _prefs.getInt(_sessionCountKey) ?? 0;
    count++;

    if (count >= _sessionThreshold) {
      count = 0; // Reset counter
      if (_interstitialAd != null) {
        _interstitialAd!.show();
        // Ad will be disposed & reloaded via the callback
      }
    }

    await _prefs.setInt(_sessionCountKey, count);
  }

  // ══════════════════════════════════════════════
  //  REWARDED ADS
  // ══════════════════════════════════════════════

  void _loadRewardedAd() {
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _isRewardedLoading = false;
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  /// Whether a rewarded ad is loaded and ready to show.
  bool get isRewardedAdReady => _rewardedAd != null;

  /// Show a rewarded ad. Returns `true` if the user earned a reward, `false` otherwise.
  ///
  /// [onRewarded] is called with the reward amount when the user finishes watching.
  Future<bool> showRewardedAd(
      {required void Function(int amount) onRewarded}) async {
    if (_rewardedAd == null) {
      // Try to reload for next time
      _loadRewardedAd();
      return false;
    }

    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Pre-load next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        onRewarded(100); // Always 100 bonus coins
      },
    );

    return rewarded;
  }

  // ══════════════════════════════════════════════
  //  BANNER ADS
  // ══════════════════════════════════════════════

  /// Create a banner ad for use on the Store screen.
  /// The caller is responsible for disposing the returned [BannerAd].
  BannerAd createBannerAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner, // 320×50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          onFailed?.call();
        },
      ),
    );
  }

  // ── Cleanup ──────────────────────────────────

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
  }
}
