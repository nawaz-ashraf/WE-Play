import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coin management service — tracks earning and spending
class CoinService {
  int _coins = 1250; // Demo starting coins

  int get coins => _coins;

  /// Award coins from gameplay
  Future<int> earnCoins(int amount) async {
    _coins += amount;
    // TODO: Update Firestore
    return _coins;
  }

  /// Spend coins in store
  Future<bool> spendCoins(int amount) async {
    if (_coins >= amount) {
      _coins -= amount;
      // TODO: Update Firestore
      return true;
    }
    return false;
  }

  /// Award daily login bonus
  Future<int> claimDailyBonus(int streak) async {
    final bonus = 10 + (streak * 5); // 15, 20, 25, 30...
    return earnCoins(bonus);
  }
}

final coinServiceProvider = Provider<CoinService>((ref) => CoinService());
