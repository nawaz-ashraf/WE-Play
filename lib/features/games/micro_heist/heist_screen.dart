import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'heist_game.dart';
import 'heist_provider.dart';
import 'heist_styles.dart';
import '../glow_merge/coin_service.dart';

// ─────────────────────────────────────────────
//  MICRO HEIST SCREEN
// ─────────────────────────────────────────────
class MicroHeistScreen extends ConsumerStatefulWidget {
  const MicroHeistScreen({super.key});

  @override
  ConsumerState<MicroHeistScreen> createState() => _MicroHeistScreenState();
}

class _MicroHeistScreenState extends ConsumerState<MicroHeistScreen> {
  late MicroHeistGame _game;
  bool _started         = false;
  bool _showingLevelBanner = false;
  bool _showingSheet    = false;

  // Swipe detection
  Offset? _swipeStart;

  @override
  void initState() {
    super.initState();
    _game = MicroHeistGame(notifier: ref.read(heistProvider.notifier));
  }

  void _startGame() {
    setState(() => _started = true);
    _game.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(heistProvider);

    // Busted
    if (state.status == HeistStatus.busted && _started && !_showingSheet) {
      _started = false;
      _showingSheet = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOver(context, state);
      });
    }

    // All levels cleared
    if (state.status == HeistStatus.gameComplete && _started && !_showingSheet) {
      _started = false;
      _showingSheet = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameComplete(context, state);
      });
    }

    // Level complete banner
    if (state.status == HeistStatus.levelComplete && !_showingLevelBanner) {
      _showingLevelBanner = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _showingLevelBanner = false);
        });
      });
    }

    return Scaffold(
      backgroundColor: HeistColors.background,
      body: Stack(
        children: [
          // ── Flame canvas + swipe wrapper ──
          GestureDetector(
            onPanStart:  (d) => _swipeStart = d.globalPosition,
            onPanEnd:    (d) => _handleSwipe(d.velocity.pixelsPerSecond),
            child: GameWidget(game: _game),
          ),

          // ── HUD ───────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(state),
                const Spacer(),
                _buildDPad(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Level complete banner ─────────
          if (_showingLevelBanner) _buildLevelBanner(state),

          // ── Start overlay ─────────────────
          if (!_started) _buildStartOverlay(),
        ],
      ),
    );
  }

  // ── Swipe → direction ─────────────────────
  void _handleSwipe(Offset velocity) {
    if (!_started) return;
    const thresh = 200.0;
    if (velocity.dx.abs() > velocity.dy.abs()) {
      if (velocity.dx > thresh)  _game.onSwipeRight();
      if (velocity.dx < -thresh) _game.onSwipeLeft();
    } else {
      if (velocity.dy > thresh)  _game.onSwipeDown();
      if (velocity.dy < -thresh) _game.onSwipeUp();
    }
  }

  // ── Top Bar ───────────────────────────────
  Widget _buildTopBar(HeistState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: HeistColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 10),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: HeistColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: HeistColors.primary.withOpacity(0.4)),
            ),
            child: Text(
              'LVL ${state.level + 1}  ${state.currentLevel.title}',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                color: HeistColors.primary,
                letterSpacing: 1,
              ),
            ),
          ),

          const Spacer(),

          // Timer
          _TimerChip(timeLeft: state.timeLeft,
              total: state.currentLevel.timeLimitSec.toDouble()),

          const SizedBox(width: 8),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                state.score.toString(),
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: HeistColors.textPrimary,
                ),
              ),
              const Text('score',
                  style: TextStyle(
                    fontSize: 9,
                    color: HeistColors.textSecondary,
                    letterSpacing: 1.5,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ── D-Pad ─────────────────────────────────
  Widget _buildDPad() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        children: [
          // Up
          Positioned(
            top: 0, left: 44,
            child: _DPadBtn(
              icon: Icons.keyboard_arrow_up_rounded,
              onTap: () => _game.onSwipeUp(),
            ),
          ),
          // Down
          Positioned(
            bottom: 0, left: 44,
            child: _DPadBtn(
              icon: Icons.keyboard_arrow_down_rounded,
              onTap: () => _game.onSwipeDown(),
            ),
          ),
          // Left
          Positioned(
            left: 0, top: 44,
            child: _DPadBtn(
              icon: Icons.keyboard_arrow_left_rounded,
              onTap: () => _game.onSwipeLeft(),
            ),
          ),
          // Right
          Positioned(
            right: 0, top: 44,
            child: _DPadBtn(
              icon: Icons.keyboard_arrow_right_rounded,
              onTap: () => _game.onSwipeRight(),
            ),
          ),
          // Centre dot
          Positioned.fill(
            child: Center(
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: HeistColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: HeistColors.primary.withOpacity(0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Level Banner ──────────────────────────
  Widget _buildLevelBanner(HeistState state) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: HeistColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HeistColors.accent.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: HeistColors.accent.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              'level ${state.level} cleared!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: HeistColors.accent,
                shadows: [
                  Shadow(
                      color: HeistColors.accent.withOpacity(0.5),
                      blurRadius: 12),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'next: ${kLevels[state.level.clamp(0, kLevels.length - 1)].title}',
              style: const TextStyle(
                fontSize: 12,
                color: HeistColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.7, 0.7),
          duration: 300.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 200.ms);
  }

  // ── Start Overlay ─────────────────────────
  Widget _buildStartOverlay() {
    return Container(
      color: HeistColors.background.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🕵️', style: TextStyle(fontSize: 52))
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.3),
            const SizedBox(height: 16),
            Text(
              'MICRO HEIST',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: HeistColors.primary,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                      color: HeistColors.primary.withOpacity(0.6),
                      blurRadius: 20),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 12),
            const Text(
              'dodge the lasers\ngrab the loot, reach the exit',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: HeistColors.textSecondary,
                height: 1.6,
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _legend(HeistColors.warn,   '= loot'),
                const SizedBox(width: 16),
                _legend(HeistColors.accent, '= exit'),
                const SizedBox(width: 16),
                _legend(HeistColors.laser,  '= laser'),
              ],
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _GlowButton(
                label: "start heist",
                color: HeistColors.primary,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  _startGame();
                },
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 11, color: HeistColors.textSecondary)),
    ],
  );

  // ── Game Over ─────────────────────────────
  Future<void> _showGameOver(BuildContext ctx, HeistState state) async {
    if (!mounted) return;

    try {
      final coinService = CoinService();
      await coinService.awardCoins(state.coins);
      await coinService.submitScore(
        gameId: 'micro_heist',
        score: state.score,
        username: 'Player',
        avatarUrl: '',
      );
    } catch (_) {
      // Firebase may not be configured; don't block the sheet
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _GameOverSheet(
        score:   state.score,
        coins:   state.coins,
        cleared: state.levelsCleared,
        busted:  true,
        onAgain: () {
          Navigator.pop(ctx);
          setState(() {
            _showingSheet = false;
            _game = MicroHeistGame(
                notifier: ref.read(heistProvider.notifier));
          });
        },
        onHome: () {
          Navigator.pop(ctx);
          Navigator.maybePop(ctx);
        },
      ),
    );
  }

  Future<void> _showGameComplete(BuildContext ctx, HeistState state) async {
    if (!mounted) return;

    try {
      final coinService = CoinService();
      await coinService.awardCoins(state.coins);
      await coinService.submitScore(
        gameId: 'micro_heist',
        score: state.score,
        username: 'Player',
        avatarUrl: '',
      );
    } catch (_) {
      // Firebase may not be configured; don't block the sheet
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _GameOverSheet(
        score:   state.score,
        coins:   state.coins,
        cleared: state.levelsCleared,
        busted:  false,
        onAgain: () {
          Navigator.pop(ctx);
          setState(() {
            _showingSheet = false;
            _game = MicroHeistGame(
                notifier: ref.read(heistProvider.notifier));
          });
        },
        onHome: () {
          Navigator.pop(ctx);
          Navigator.maybePop(ctx);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  D-PAD BUTTON
// ─────────────────────────────────────────────
class _DPadBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DPadBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: HeistColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HeistColors.primary.withOpacity(0.3)),
        ),
        child: Icon(icon, color: HeistColors.primary, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TIMER CHIP
// ─────────────────────────────────────────────
class _TimerChip extends StatelessWidget {
  final double timeLeft;
  final double total;

  const _TimerChip({required this.timeLeft, required this.total});

  @override
  Widget build(BuildContext context) {
    final isLow = timeLeft < 6;
    final color = isLow ? HeistColors.energy : HeistColors.warn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '${timeLeft.ceil()}s',
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GAME OVER / COMPLETE SHEET
// ─────────────────────────────────────────────
class _GameOverSheet extends StatelessWidget {
  final int  score;
  final int  coins;
  final int  cleared;
  final bool busted;
  final VoidCallback onAgain;
  final VoidCallback onHome;

  const _GameOverSheet({
    required this.score,
    required this.coins,
    required this.cleared,
    required this.busted,
    required this.onAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HeistColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: HeistColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            busted ? 'laser caught you 🚨' : 'heist complete! 🏆',
            style: const TextStyle(
              fontSize: 13,
              color: HeistColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            busted ? 'busted' : 'clean escape',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: busted ? HeistColors.energy : HeistColors.accent,
              shadows: [
                Shadow(
                  color: (busted ? HeistColors.energy : HeistColors.accent)
                      .withOpacity(0.5),
                  blurRadius: 16,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('SCORE',   score.toString(),   HeistColors.primary),
              _stat('LEVELS',  cleared.toString(), HeistColors.accent),
              _stat('COINS',   '+$coins',          const Color(0xFFFFD740)),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 32),

          _GlowButton(
            label: busted ? 'try again' : 'play again',
            color: busted ? HeistColors.energy : HeistColors.accent,
            onTap: onAgain,
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 12),

          TextButton(
            onPressed: onHome,
            child: const Text('back to lobby',
                style: TextStyle(color: HeistColors.textSecondary, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(
    children: [
      Text(value,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          )),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(
            fontSize: 10,
            color: HeistColors.textSecondary,
            letterSpacing: 1.5,
            fontFamily: 'Orbitron',
          )),
    ],
  );
}

// ─────────────────────────────────────────────
//  GLOW BUTTON
// ─────────────────────────────────────────────
class _GlowButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlowButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.45), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
