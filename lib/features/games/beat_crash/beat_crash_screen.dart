import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'beat_crash_game.dart';
import 'beat_crash_provider.dart';
import 'beat_crash_styles.dart';
import '../glow_merge/coin_service.dart';

// ─────────────────────────────────────────────
//  BEAT CRASH SCREEN  (Flutter wrapper)
// ─────────────────────────────────────────────
class BeatCrashScreen extends ConsumerStatefulWidget {
  const BeatCrashScreen({super.key});

  @override
  ConsumerState<BeatCrashScreen> createState() => _BeatCrashScreenState();
}

class _BeatCrashScreenState extends ConsumerState<BeatCrashScreen> {
  late BeatCrashGame _game;
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
    _game = BeatCrashGame(
      notifier: ref.read(beatCrashProvider.notifier),
    );
  }

  void _startGame() {
    setState(() => _gameStarted = true);
    _game.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(beatCrashProvider);

    // Show game over
    if (state.status == BeatGameStatus.over && _gameStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOver(context, state);
      });
    }

    return Scaffold(
      backgroundColor: BeatColors.background,
      body: Stack(
        children: [
          // ── Flame canvas ──────────────────
          GameWidget(game: _game),

          // ── HUD overlay ───────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(state),
                const Spacer(),
                _buildComboBar(state),
                const SizedBox(height: 90), // space above target zone
              ],
            ),
          ),

          // ── Start overlay ─────────────────
          if (!_gameStarted) _buildStartOverlay(),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────
  Widget _buildTopBar(BeatCrashState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: BeatColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),

          // Score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.score.toString(),
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: BeatColors.textPrimary,
                  ),
                ),
                Text(
                  'score',
                  style: TextStyle(
                    fontSize: 10,
                    color: BeatColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Timer ring
          _TimerRing(
            timeLeft: state.timeLeft,
            total: BeatConst.sessionSeconds,
          ),

          const SizedBox(width: 12),

          // Multiplier
          _MultiplierBadge(multiplier: state.multiplier),
        ],
      ),
    );
  }

  // ── Combo Bar ─────────────────────────────
  Widget _buildComboBar(BeatCrashState state) {
    if (state.combo == 0) return const SizedBox.shrink();

    final nextThreshIdx = BeatConst.comboThresholds
        .indexWhere((t) => state.combo < t);
    final nextThresh = nextThreshIdx >= 0
        ? BeatConst.comboThresholds[nextThreshIdx]
        : BeatConst.comboThresholds.last;
    final prevThresh = nextThreshIdx > 0
        ? BeatConst.comboThresholds[nextThreshIdx - 1]
        : 0;
    final progress = nextThresh == prevThresh
        ? 1.0
        : (state.combo - prevThresh) / (nextThresh - prevThresh);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.combo}x combo',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  color: BeatColors.accent,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'next: ${nextThresh}',
                style: const TextStyle(
                  fontSize: 10,
                  color: BeatColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: BeatColors.surface,
              valueColor: const AlwaysStoppedAnimation(BeatColors.accent),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Start overlay ─────────────────────────
  Widget _buildStartOverlay() {
    return Container(
      color: BeatColors.background.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BEAT CRASH',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: BeatColors.primary,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                      color: BeatColors.primary.withOpacity(0.6),
                      blurRadius: 24),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
            const SizedBox(height: 12),
            const Text(
              'tap each lane when the block\nhits the glowing line',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: BeatColors.textSecondary,
                height: 1.6,
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 40),
            _GlowButton(
              label: "let's go",
              color: BeatColors.primary,
              onTap: () {
                HapticFeedback.heavyImpact();
                _startGame();
              },
            ).animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }

  // ── Game Over ─────────────────────────────
  Future<void> _showGameOver(BuildContext ctx, BeatCrashState state) async {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _GameOverSheet(
        score:    state.score,
        combo:    state.maxCombo,
        coins:    state.coins,
        best:     state.bestScore,
        onAgain: () {
          Navigator.pop(ctx);
          setState(() {
            _gameStarted = false;
            _game = BeatCrashGame(
              notifier: ref.read(beatCrashProvider.notifier),
            );
          });
        },
        onHome: () {
          Navigator.pop(ctx);
          Navigator.maybePop(ctx);
        },
      ),
    );

    // Award coins to Firestore
    final coinService = CoinService();
    await coinService.awardCoins(state.coins);
  }
}

// ─────────────────────────────────────────────
//  TIMER RING
// ─────────────────────────────────────────────
class _TimerRing extends StatelessWidget {
  final double timeLeft;
  final double total;

  const _TimerRing({required this.timeLeft, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = (timeLeft / total).clamp(0.0, 1.0);
    final isLow    = timeLeft < 8;
    final color    = isLow ? BeatColors.energy : BeatColors.primary;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: BeatColors.surface,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            timeLeft.ceil().toString(),
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MULTIPLIER BADGE
// ─────────────────────────────────────────────
class _MultiplierBadge extends StatelessWidget {
  final double multiplier;

  const _MultiplierBadge({required this.multiplier});

  @override
  Widget build(BuildContext context) {
    if (multiplier <= 1.0) return const SizedBox(width: 44);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: BeatColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BeatColors.accent.withOpacity(0.5)),
      ),
      child: Center(
        child: Text(
          '${multiplier.toInt()}x',
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: BeatColors.accent,
          ),
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.8, 0.8),
      duration: 200.ms,
      curve: Curves.elasticOut,
    );
  }
}

// ─────────────────────────────────────────────
//  GAME OVER SHEET
// ─────────────────────────────────────────────
class _GameOverSheet extends StatelessWidget {
  final int score;
  final int combo;
  final int coins;
  final int best;
  final VoidCallback onAgain;
  final VoidCallback onHome;

  const _GameOverSheet({
    required this.score,
    required this.combo,
    required this.coins,
    required this.best,
    required this.onAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final isNewBest = score >= best;

    return Container(
      decoration: const BoxDecoration(
        color: BeatColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: BeatColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            isNewBest ? 'you ate that 🔥' : 'rip the combo 😭',
            style: const TextStyle(
              fontSize: 13,
              color: BeatColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'time\'s up',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: BeatColors.energy,
              shadows: [Shadow(
                color: BeatColors.energy.withOpacity(0.5),
                blurRadius: 16,
              )],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 28),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('SCORE',    score.toString(), BeatColors.primary),
              _stat('MAX COMBO',combo.toString(), BeatColors.accent),
              _stat('COINS',   '+$coins',         const Color(0xFFFFD740)),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 32),

          _GlowButton(
            label: 'play again',
            color: BeatColors.primary,
            onTap: onAgain,
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 12),

          TextButton(
            onPressed: onHome,
            child: const Text(
              'back to lobby',
              style: TextStyle(color: BeatColors.textSecondary, fontSize: 14),
            ),
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
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          )),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(
            fontSize: 10,
            color: BeatColors.textSecondary,
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
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.45), blurRadius: 20, spreadRadius: 2),
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
