import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:we_play/core/providers/shared_prefs_provider.dart';
import 'package:we_play/core/services/ad_service.dart';

/// Provides a singleton [AdService] wired to SharedPreferences.
///
/// The service is created lazily and initialized when first accessed.
/// Ads are pre-loaded during initialization.
final adServiceProvider = Provider<AdService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = AdService(prefs);
  // Initialization happens in main.dart to ensure it completes before app runs.
  return service;
});
