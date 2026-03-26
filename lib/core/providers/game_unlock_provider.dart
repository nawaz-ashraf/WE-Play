import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';
import '../models/store_game_model.dart';
import 'coin_provider.dart';

class GameUnlockNotifier extends Notifier<List<String>> {
  static const _unlockedKey = 'user_unlocked_games';

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getStringList(_unlockedKey) ?? [];
  }

  bool isUnlocked(String gameId) {
    // Default games are always unlocked
    if (GameCatalog.allGames.any((g) => g.id == gameId && g.isDefaultGame)) {
      return true;
    }
    return state.contains(gameId);
  }

  bool buyGame(String gameId, int price) {
    if (state.contains(gameId)) return true; // already bought
    
    // Attempt purchase via coin provider
    final success = ref.read(coinNotifierProvider.notifier).spendCoins(price);
    if (success) {
      state = [...state, gameId];
      ref.read(sharedPreferencesProvider).setStringList(_unlockedKey, state);
      return true;
    }
    return false;
  }
  
  List<StoreGameModel> get unlockedStoreGames {
    return GameCatalog.allGames
      .where((g) => !g.isDefaultGame && state.contains(g.id))
      .toList();
  }

  List<StoreGameModel> get defaultGames {
    return GameCatalog.allGames.where((g) => g.isDefaultGame).toList();
  }
  
  List<StoreGameModel> get lobbyGames {
     return [
       ...defaultGames,
       ...unlockedStoreGames,
     ];
  }
}

final gameUnlockProvider = NotifierProvider<GameUnlockNotifier, List<String>>(() => GameUnlockNotifier());
