import 'package:flutter/material.dart';

/// Model representing a game in the app ecosystem
class StoreGameModel {
  final String id;
  final String title;
  final String description;
  final int coinPrice;
  final bool isDefaultGame;
  final IconData icon;
  final Color accentColor;
  final String emoji;
  final Color iconBg;
  final String route;
  final int fakePlayers;
  final bool isLocked;
  final int unlockCost;
  final String category;

  const StoreGameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coinPrice,
    required this.isDefaultGame,
    required this.icon,
    required this.accentColor,
    this.emoji = '🎮',
    Color? iconBg,
    String? route,
    this.fakePlayers = 400,
    bool? isLocked,
    int? unlockCost,
    this.category = 'free',
  })  : iconBg = iconBg ?? accentColor,
        route = route ?? '/lobby/game/$id',
        isLocked = isLocked ?? !isDefaultGame,
        unlockCost = unlockCost ?? coinPrice;
}

/// Static catalog of all games currently available in-app
class GameCatalog {
  static const List<StoreGameModel> allGames = [
    // --- Default Games ---
    StoreGameModel(
      id: 'beat_crash',
      title: 'Beat Crash',
      description: 'rhythm tap madness',
      coinPrice: 0,
      isDefaultGame: true,
      icon: Icons.music_note_rounded,
      accentColor: Color(0xFFFF3E6C),
    ),
    StoreGameModel(
      id: 'micro_heist',
      title: 'Micro Heist',
      description: 'stealth mode on',
      coinPrice: 0,
      isDefaultGame: true,
      icon: Icons.visibility_off_rounded,
      accentColor: Color(0xFF00F5A0),
    ),
    StoreGameModel(
      id: 'glow_merge',
      title: 'Glow Merge',
      description: 'merge the glow',
      coinPrice: 0,
      isDefaultGame: true,
      icon: Icons.blur_on_rounded,
      accentColor: Color(0xFF00C853),
    ),
    StoreGameModel(
      id: 'flappy_bird',
      title: 'Flappy Bird',
      description: 'dodge the pipes',
      coinPrice: 0,
      isDefaultGame: true,
      icon: Icons.flutter_dash_rounded,
      accentColor: Color(0xFF7B61FF),
    ),
    StoreGameModel(
      id: 'hot_air_balloon',
      title: 'Hot Air Balloon',
      description: 'rise and survive',
      coinPrice: 500,
      isDefaultGame: false,
      icon: Icons.air_rounded,
      accentColor: Color(0xFF7B61FF),
      emoji: '🎈',
      iconBg: Color(0xFF1A0A3D),
      route: '/lobby/game/hot_air_balloon',
      fakePlayers: 867,
      category: 'premium',
    ),
    StoreGameModel(
      id: 'trex_run',
      title: 'T-Rex Run',
      description: 'jump and duck',
      coinPrice: 500,
      isDefaultGame: false,
      icon: Icons.directions_run_rounded,
      accentColor: Color(0xFF00E5A8),
      emoji: '🦖',
      iconBg: Color(0xFF0E2A1F),
      route: '/lobby/game/trex_run',
      fakePlayers: 993,
      category: 'premium',
    ),
    StoreGameModel(
      id: 'doodle_jump',
      title: 'Doodle Jump',
      description: 'climb forever',
      coinPrice: 500,
      isDefaultGame: false,
      icon: Icons.rocket_launch_rounded,
      accentColor: Color(0xFF4FC3F7),
      emoji: '🚀',
      iconBg: Color(0xFF0A1B3D),
      route: '/lobby/game/doodle_jump',
      fakePlayers: 1104,
      category: 'premium',
    ),

    // --- Premium / Store Games ---
    StoreGameModel(
      id: 'memory_puzzle',
      title: 'Memory Puzzle',
      description: 'flip & match',
      coinPrice: 0,
      isDefaultGame: true,
      icon: Icons.style_rounded,
      accentColor: Color(0xFFFF3E6C),
      emoji: '🧠',
      fakePlayers: 904,
      category: 'free',
    ),
    StoreGameModel(
      id: 'snake_game',
      title: 'Snake Game',
      description: 'grow or die',
      coinPrice: 0,
      isDefaultGame: true,
      icon: Icons.pest_control_rounded,
      accentColor: Color(0xFF00F5A0),
      emoji: '🐍',
      fakePlayers: 1022,
      category: 'free',
    ),

    // --- New Premium Games ---
    StoreGameModel(
      id: 'block_blast',
      title: 'Block Blast',
      description: 'clear the board',
      coinPrice: 800,
      isDefaultGame: false,
      icon: Icons.grid_view_rounded,
      accentColor: Color(0xFF7B61FF),
      fakePlayers: 932,
      category: 'premium',
    ),
    StoreGameModel(
      id: 'wood_block',
      title: 'Wood Block',
      description: 'fit the pieces',
      coinPrice: 600,
      isDefaultGame: false,
      icon: Icons.carpenter_rounded,
      accentColor: Color(0xFFCD853F),
      fakePlayers: 781,
      category: 'premium',
    ),
    StoreGameModel(
      id: 'color_switch',
      title: 'Color Switch',
      description: 'match the color',
      coinPrice: 500,
      isDefaultGame: false,
      icon: Icons.palette_rounded,
      accentColor: Color(0xFF4FC3F7),
      fakePlayers: 1193,
      category: 'premium',
    ),
  ];

  static final List<StoreGameModel> premiumGames =
      allGames.where((g) => g.isLocked).toList();
}
