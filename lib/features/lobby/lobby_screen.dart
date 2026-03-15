import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/core/widgets/coin_display.dart';
import 'package:we_play/core/widgets/game_card.dart';

/// Game metadata for lobby display
class _GameInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color accentColor;
  final int highScore;
  final int playerCount;

  const _GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.highScore = 0,
    this.playerCount = 0,
  });
}

const _games = [
  _GameInfo(
    id: 'beat_crash',
    name: 'Beat Crash',
    description: 'rhythm tap madness',
    icon: Icons.music_note_rounded,
    accentColor: WePlayColors.energy,
    highScore: 12400,
    playerCount: 842,
  ),
  _GameInfo(
    id: 'snack_stackers',
    name: 'Snack Stackers',
    description: 'stack it up',
    icon: Icons.fastfood_rounded,
    accentColor: WePlayColors.amber,
    highScore: 850,
    playerCount: 631,
  ),
  _GameInfo(
    id: 'micro_heist',
    name: 'Micro Heist',
    description: 'stealth mode on',
    icon: Icons.visibility_off_rounded,
    accentColor: WePlayColors.secondary,
    highScore: 15,
    playerCount: 524,
  ),
  _GameInfo(
    id: 'glow_merge',
    name: 'Glow Merge',
    description: 'merge the glow',
    icon: Icons.blur_on_rounded,
    accentColor: WePlayColors.primary,
    highScore: 2048,
    playerCount: 1203,
  ),
  _GameInfo(
    id: 'flick_royale',
    name: 'Flick Royale',
    description: 'flick to win',
    icon: Icons.sports_hockey_rounded,
    accentColor: WePlayColors.teal,
    highScore: 9,
    playerCount: 378,
  ),
];

/// Now Playing banner — horizontal scroll showing top players
class _NowPlayingBanner extends StatelessWidget {
  const _NowPlayingBanner();

  @override
  Widget build(BuildContext context) {
    final leaders = [
      ('xXblaze99Xx', '28.4k', WePlayColors.energy),
      ('neon_queen', '24.1k', WePlayColors.primary),
      ('sk8r_boi', '21.8k', WePlayColors.secondary),
      ('vibes.only', '19.2k', WePlayColors.amber),
      ('ghostt_', '17.5k', WePlayColors.teal),
    ];

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: leaders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (name, score, color) = leaders[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withAlpha(40),
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: WePlayColors.textPrimary,
                      ),
                    ),
                    Text(
                      score,
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Main lobby screen — game selection home
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoPulse;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _logoPulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WePlayColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar with logo + user info
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Pulsing logo
                    ScaleTransition(
                      scale: _logoPulse,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            WePlayColors.primary,
                            WePlayColors.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'WE PLAY',
                          style: GoogleFonts.orbitron(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Coin count
                    const CoinDisplay(coins: 1250),
                    const SizedBox(width: 10),
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [WePlayColors.primary, WePlayColors.energy],
                        ),
                        border: Border.all(
                          color: WePlayColors.primary.withAlpha(80),
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Daily streak banner
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        WePlayColors.amber.withAlpha(20),
                        WePlayColors.energy.withAlpha(10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WePlayColors.amber.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: WePlayColors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '5 day streak 🔥',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: WePlayColors.amber,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'claim +35 coins',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: WePlayColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          color: WePlayColors.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            // "now playing" section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: WePlayColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'now playing',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: WePlayColors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Now playing banner
            const SliverToBoxAdapter(
              child: _NowPlayingBanner(),
            ),

            // Games section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'pick your vibe ✨',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: WePlayColors.textPrimary,
                  ),
                ),
              ),
            ),

            // Games grid — 2 column + 1 wide
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // First row: 2 cards
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 170,
                            child: GameCard(
                              gameId: _games[0].id,
                              name: _games[0].name,
                              description: _games[0].description,
                              icon: _games[0].icon,
                              accentColor: _games[0].accentColor,
                              highScore: _games[0].highScore,
                              playerCount: _games[0].playerCount,
                              onTap: () =>
                                  context.push('/lobby/game/beat_crash'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 170,
                            child: GameCard(
                              gameId: _games[1].id,
                              name: _games[1].name,
                              description: _games[1].description,
                              icon: _games[1].icon,
                              accentColor: _games[1].accentColor,
                              highScore: _games[1].highScore,
                              playerCount: _games[1].playerCount,
                              onTap: () =>
                                  context.push('/lobby/game/snack_stackers'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Second row: 2 cards
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 170,
                            child: GameCard(
                              gameId: _games[2].id,
                              name: _games[2].name,
                              description: _games[2].description,
                              icon: _games[2].icon,
                              accentColor: _games[2].accentColor,
                              highScore: _games[2].highScore,
                              playerCount: _games[2].playerCount,
                              onTap: () =>
                                  context.push('/lobby/game/micro_heist'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 170,
                            child: GameCard(
                              gameId: _games[3].id,
                              name: _games[3].name,
                              description: _games[3].description,
                              icon: _games[3].icon,
                              accentColor: _games[3].accentColor,
                              highScore: _games[3].highScore,
                              playerCount: _games[3].playerCount,
                              onTap: () =>
                                  context.push('/lobby/game/glow_merge'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Wide card
                    SizedBox(
                      height: 80,
                      child: GameCard(
                        gameId: _games[4].id,
                        name: _games[4].name,
                        description: _games[4].description,
                        icon: _games[4].icon,
                        accentColor: _games[4].accentColor,
                        highScore: _games[4].highScore,
                        playerCount: _games[4].playerCount,
                        isWide: true,
                        onTap: () => context.push('/lobby/game/flick_royale'),
                      ),
                    ),
                    const SizedBox(height: 24),
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
