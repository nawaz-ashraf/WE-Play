import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/core/widgets/we_play_button.dart';

/// Game names and accent colors
const _gameData = {
  'beat_crash': ('Beat Crash', WePlayColors.energy, Icons.music_note_rounded),
  'snack_stackers': (
    'Snack Stackers',
    WePlayColors.amber,
    Icons.fastfood_rounded
  ),
  'micro_heist': (
    'Micro Heist',
    WePlayColors.secondary,
    Icons.visibility_off_rounded
  ),
  'glow_merge': ('Glow Merge', WePlayColors.primary, Icons.blur_on_rounded),
  'flick_royale': (
    'Flick Royale',
    WePlayColors.teal,
    Icons.sports_hockey_rounded
  ),
};

/// Generic game placeholder screen — used for all 5 games initially
class GameScreen extends StatelessWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final data = _gameData[gameId];
    final name = data?.$1 ?? 'Unknown Game';
    final color = data?.$2 ?? WePlayColors.primary;
    final icon = data?.$3 ?? Icons.videogame_asset_rounded;

    return Scaffold(
      backgroundColor: WePlayColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.go('/lobby'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: WePlayColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WePlayColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_rounded,
                            size: 18, color: WePlayColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'back',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: WePlayColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Game placeholder
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withAlpha(40),
                            color.withAlpha(10),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(60),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 48, color: color),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      name,
                      style: GoogleFonts.orbitron(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: WePlayColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'dropping soon 🚀',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: WePlayColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    WePlayButton(
                      label: 'back to lobby',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => context.go('/lobby'),
                      gradientColors: [color, color.withAlpha(180)],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
