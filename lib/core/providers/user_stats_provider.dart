import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';

class UserStats {
  final int gamesPlayed;
  final int loginStreak;
  final String lastLoginDate;
  final int adCoins;

  UserStats({
    required this.gamesPlayed,
    required this.loginStreak,
    required this.lastLoginDate,
    required this.adCoins,
  });

  UserStats copyWith({
    int? gamesPlayed,
    int? loginStreak,
    String? lastLoginDate,
    int? adCoins,
  }) {
    return UserStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      loginStreak: loginStreak ?? this.loginStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      adCoins: adCoins ?? this.adCoins,
    );
  }
}

final userStatsProvider = NotifierProvider<UserStatsNotifier, UserStats>(UserStatsNotifier.new);

class UserStatsNotifier extends Notifier<UserStats> {
  static const _gamesPlayedKey = 'stats_games_played';
  static const _loginStreakKey = 'stats_login_streak';
  static const _lastLoginDateKey = 'stats_last_login_date';
  static const _adCoinsKey = 'stats_ad_coins';

  @override
  UserStats build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    int gamesPlayed = prefs.getInt(_gamesPlayedKey) ?? 127; // Default 127 from previous hardcoded UI
    int loginStreak = prefs.getInt(_loginStreakKey) ?? 5; // Default 5
    String lastLoginDate = prefs.getString(_lastLoginDateKey) ?? '';
    int adCoins = prefs.getInt(_adCoinsKey) ?? 0;

    // Login streak logic
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    
    if (lastLoginDate != todayStr) {
      if (lastLoginDate.isNotEmpty) {
        final lastLoginParts = lastLoginDate.split('-');
        if (lastLoginParts.length == 3) {
          final lastDate = DateTime(
            int.parse(lastLoginParts[0]),
            int.parse(lastLoginParts[1]),
            int.parse(lastLoginParts[2]),
          );
          
          final difference = today.difference(lastDate).inDays;
          if (difference == 1) {
            loginStreak += 1; // Uninterrupted daily login
          } else if (difference > 1) {
            loginStreak = 1; // Streak broken
          }
        }
      } else {
        // First ever login
        loginStreak = 1;
      }
      lastLoginDate = todayStr;
      prefs.setInt(_loginStreakKey, loginStreak);
      prefs.setString(_lastLoginDateKey, lastLoginDate);
    }

    return UserStats(
      gamesPlayed: gamesPlayed,
      loginStreak: loginStreak,
      lastLoginDate: lastLoginDate,
      adCoins: adCoins,
    );
  }

  void incrementGamesPlayed() {
    final prefs = ref.read(sharedPreferencesProvider);
    final count = state.gamesPlayed + 1;
    prefs.setInt(_gamesPlayedKey, count);
    state = state.copyWith(gamesPlayed: count);
  }

  void addAdCoins(int coins) {
    final prefs = ref.read(sharedPreferencesProvider);
    final newCoins = state.adCoins + coins;
    prefs.setInt(_adCoinsKey, newCoins);
    state = state.copyWith(adCoins: newCoins);
  }
}
