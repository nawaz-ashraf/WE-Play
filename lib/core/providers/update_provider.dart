import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:we_play/core/utils/version_utils.dart';

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);

const _kDismissedVersionKey = 'dismissed_update_version';
const _kUpdateChecksEnabledFromVersion = '1.0.2';
const _kAndroidPackageName = 'com.weplay.app.we_play';

class UpdateState {
  final bool isChecking;
  final bool hasCheckedThisSession;
  final bool hasShownThisSession;
  final bool shouldShowPopup;
  final String? currentVersion;
  final String? latestVersion;

  const UpdateState({
    this.isChecking = false,
    this.hasCheckedThisSession = false,
    this.hasShownThisSession = false,
    this.shouldShowPopup = false,
    this.currentVersion,
    this.latestVersion,
  });

  UpdateState copyWith({
    bool? isChecking,
    bool? hasCheckedThisSession,
    bool? hasShownThisSession,
    bool? shouldShowPopup,
    String? currentVersion,
    String? latestVersion,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      hasCheckedThisSession:
          hasCheckedThisSession ?? this.hasCheckedThisSession,
      hasShownThisSession: hasShownThisSession ?? this.hasShownThisSession,
      shouldShowPopup: shouldShowPopup ?? this.shouldShowPopup,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
    );
  }
}

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() {
    return const UpdateState();
  }

  Future<void> checkForUpdate() async {
    if (state.hasCheckedThisSession || state.isChecking) {
      return;
    }

    state = state.copyWith(isChecking: true);

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final latestVersion = await _fetchLatestVersion();

    // Update prompts are disabled for initial releases.
    if (!isVersionAtLeast(currentVersion, _kUpdateChecksEnabledFromVersion)) {
      state = state.copyWith(
        isChecking: false,
        hasCheckedThisSession: true,
        shouldShowPopup: false,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final dismissedVersion = prefs.getString(_kDismissedVersionKey);

    final hasUpdate = isVersionGreaterThan(latestVersion, currentVersion);
    final isDismissedForLatest = dismissedVersion == latestVersion;

    state = state.copyWith(
      isChecking: false,
      hasCheckedThisSession: true,
      shouldShowPopup: hasUpdate && !isDismissedForLatest,
      currentVersion: currentVersion,
      latestVersion: latestVersion,
    );
  }

  void markPopupShownThisSession() {
    state = state.copyWith(hasShownThisSession: true);
  }

  Future<void> dismissForCurrentLatestVersion() async {
    final latestVersion = state.latestVersion;
    if (latestVersion == null || latestVersion.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDismissedVersionKey, latestVersion);

    state = state.copyWith(shouldShowPopup: false);
  }

  Future<void> openStorePage() async {
    final marketUri = Uri.parse('market://details?id=$_kAndroidPackageName');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_kAndroidPackageName',
    );

    final openedMarket = await launchUrl(
      marketUri,
      mode: LaunchMode.externalApplication,
    );

    if (!openedMarket) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<String> _fetchLatestVersion() async {
    // Replace with Remote Config / backend value when available.
    return '1.0.1';
  }
}
