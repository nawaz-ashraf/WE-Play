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

final userStatsProvider =
    NotifierProvider<UserStatsNotifier, UserStats>(UserStatsNotifier.new);

class UserStatsNotifier extends Notifier<UserStats> {
  static const _gamesPlayedKey = 'stats_games_played';
  static const _loginStreakKey = 'stats_login_streak';
  static const _lastLoginDateKey = 'stats_last_login_date';
  static const _adCoinsKey = 'stats_ad_coins';

  @override
  UserStats build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final next = UserStats(
      gamesPlayed: prefs.getInt(_gamesPlayedKey) ?? 0,
      loginStreak: prefs.getInt(_loginStreakKey) ?? 0,
      lastLoginDate: prefs.getString(_lastLoginDateKey) ?? '',
      adCoins: prefs.getInt(_adCoinsKey) ?? 0,
    );

    return _applyDailyStreak(next, persist: true);
  }

  void refreshDailyStreak() {
    final next = _applyDailyStreak(state, persist: true);
    if (next.loginStreak != state.loginStreak ||
        next.lastLoginDate != state.lastLoginDate) {
      state = next;
    }
  }

  UserStats _applyDailyStreak(UserStats current, {required bool persist}) {
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    if (current.lastLoginDate == todayKey) {
      return current;
    }

    int nextStreak;
    if (current.lastLoginDate.isEmpty) {
      nextStreak = 1;
    } else {
      final lastDate = _parseDateKey(current.lastLoginDate);
      if (lastDate == null) {
        nextStreak = 1;
      } else {
        final difference = _stripTime(today).difference(lastDate).inDays;
        if (difference == 1) {
          nextStreak = current.loginStreak + 1;
        } else {
          nextStreak = 1;
        }
      }
    }

    if (persist) {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setInt(_loginStreakKey, nextStreak);
      prefs.setString(_lastLoginDateKey, todayKey);
    }

    return current.copyWith(
      loginStreak: nextStreak,
      lastLoginDate: todayKey,
    );
  }

  DateTime? _parseDateKey(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
