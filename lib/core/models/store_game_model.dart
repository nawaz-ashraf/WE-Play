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

  const StoreGameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coinPrice,
    required this.isDefaultGame,
    required this.icon,
    required this.accentColor,
  });
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
      id: 'snack_stackers',
      title: 'Snack Stackers',
      description: 'stack it up',
      coinPrice: 0,
      isDefaultGame: true,
      icon: Icons.fastfood_rounded,
      accentColor: Color(0xFFFFD740),
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

    // --- Premium / Store Games ---
    StoreGameModel(
      id: 'memory_puzzle',
      title: 'Memory Puzzle',
      description: 'flip & match',
      coinPrice: 500, // example price
      isDefaultGame: false,
      icon: Icons.style_rounded,
      accentColor: Color(0xFFFF3E6C),
    ),
    StoreGameModel(
      id: 'snake_game',
      title: 'Snake Game',
      description: 'grow or die',
      coinPrice: 750,
      isDefaultGame: false,
      icon: Icons.pest_control_rounded,
      accentColor: Color(0xFF00F5A0),
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
    ),
    StoreGameModel(
      id: 'wood_block',
      title: 'Wood Block',
      description: 'fit the pieces',
      coinPrice: 600,
      isDefaultGame: false,
      icon: Icons.carpenter_rounded,
      accentColor: Color(0xFFCD853F),
    ),
    StoreGameModel(
      id: 'color_switch',
      title: 'Color Switch',
      description: 'match the color',
      coinPrice: 500,
      isDefaultGame: false,
      icon: Icons.palette_rounded,
      accentColor: Color(0xFF4FC3F7),
    ),
  ];
}
