import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coin_provider.dart';
import 'user_stats_provider.dart';

class AppBootstrapper {
  const AppBootstrapper(this.ref);

  final Ref ref;

  Future<void> initializeSession() async {
    ref.read(coinNotifierProvider.notifier).initializeUserCoins();
    ref.read(userStatsProvider.notifier).refreshDailyStreak();
  }
}

final appBootstrapProvider = Provider<AppBootstrapper>(
  (ref) => AppBootstrapper(ref),
);
