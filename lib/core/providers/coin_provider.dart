import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';

class CoinNotifier extends Notifier<int> {
  static const _coinsKey = 'user_coins_stored';

  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    // Return saved coins or default to 1250 (as per previous mock)
    return prefs.getInt(_coinsKey) ?? 1250;
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

final coinNotifierProvider = NotifierProvider<CoinNotifier, int>(() => CoinNotifier());
