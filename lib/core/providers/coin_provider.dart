import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_prefs_provider.dart';

class CoinNotifier extends Notifier<int> {
  static const _coinsKey = 'user_coins_stored';
  static const _userInitKey = 'user_account_initialized_v1';
  static const _newUserBonusKey = 'user_new_user_bonus_granted_v1';

  static const startingCoins = 1000;
  static const _legacyStartingCoins = 1250;

  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt(_coinsKey) ?? startingCoins;
  }

  void initializeUserCoins() {
    final prefs = ref.read(sharedPreferencesProvider);
    final isInitialized = prefs.getBool(_userInitKey) ?? false;

    if (isInitialized) {
      if (!prefs.containsKey(_coinsKey)) {
        final fallback = _hasExistingAccountState(prefs)
            ? _legacyStartingCoins
            : startingCoins;
        prefs.setInt(_coinsKey, fallback);
        state = fallback;
      }
      return;
    }

    final hasExistingState = _hasExistingAccountState(prefs);
    if (hasExistingState) {
      if (!prefs.containsKey(_coinsKey)) {
        prefs.setInt(_coinsKey, _legacyStartingCoins);
      }
    } else {
      prefs.setInt(_coinsKey, startingCoins);
      prefs.setBool(_newUserBonusKey, true);
    }

    prefs.setBool(_userInitKey, true);
    state = prefs.getInt(_coinsKey) ?? startingCoins;
  }

  bool _hasExistingAccountState(SharedPreferences prefs) {
    return prefs.containsKey(_coinsKey) ||
        prefs.containsKey('user_unlocked_games') ||
        prefs.containsKey('stats_games_played') ||
        prefs.containsKey('stats_last_login_date') ||
        prefs.containsKey('stats_login_streak');
  }

  void earnCoins(int amount) {
    if (amount <= 0) return;
    state += amount;
    ref.read(sharedPreferencesProvider).setInt(_coinsKey, state);
  }

  bool spendCoins(int amount) {
    if (amount <= 0) return true;
    if (state >= amount) {
      state -= amount;
      ref.read(sharedPreferencesProvider).setInt(_coinsKey, state);
      return true;
    }
    return false;
  }
}

final coinNotifierProvider =
    NotifierProvider<CoinNotifier, int>(() => CoinNotifier());
