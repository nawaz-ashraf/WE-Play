import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/core/widgets/coin_display.dart';
import 'package:we_play/core/widgets/game_card.dart';
import 'package:we_play/core/providers/game_unlock_provider.dart';
import 'package:we_play/core/providers/update_provider.dart';
import 'package:we_play/core/widgets/update_popup.dart';




/// Main lobby screen — game selection home
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen>
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

    // Check for app update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final needsUpdate = ref.read(updateProvider);
        if (needsUpdate) {
          UpdatePopup.show(context, onSkip: () {
            ref.read(updateProvider.notifier).markUpdateDismissed();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtleText = onSurface.withAlpha(140);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    const CoinDisplay(),
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
                          color: subtleText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          color: subtleText, size: 16),
                    ],
                  ),
                ),
              ),
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
                    color: onSurface,
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
                    // Dynamic games grid depending on unlocked games
                    Builder(builder: (context) {
                      final unlockedGames = ref.watch(gameUnlockProvider.notifier).lobbyGames;
                      final List<Widget> rows = [];
                      for (int i = 0; i < unlockedGames.length; i += 2) {
                        rows.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 170,
                                    child: GameCard(
                                      gameId: unlockedGames[i].id,
                                      name: unlockedGames[i].title,
                                      description: unlockedGames[i].description,
                                      icon: unlockedGames[i].icon,
                                      accentColor: unlockedGames[i].accentColor,
                                      highScore: 0,
                                      playerCount: 400 + (unlockedGames[i].title.length * 20),
                                      onTap: () => context.push('/lobby/game/${unlockedGames[i].id}'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (i + 1 < unlockedGames.length)
                                  Expanded(
                                    child: SizedBox(
                                      height: 170,
                                      child: GameCard(
                                        gameId: unlockedGames[i + 1].id,
                                        name: unlockedGames[i + 1].title,
                                        description: unlockedGames[i + 1].description,
                                        icon: unlockedGames[i + 1].icon,
                                        accentColor: unlockedGames[i + 1].accentColor,
                                        highScore: 0,
                                        playerCount: 400 + (unlockedGames[i + 1].title.length * 20),
                                        onTap: () => context.push('/lobby/game/${unlockedGames[i + 1].id}'),
                                      ),
                                    ),
                                  )
                                else
                                  const Expanded(child: SizedBox.shrink()),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return Column(
                        children: rows,
                      );
                    }),
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
