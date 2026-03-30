import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'flappy_game.dart';
import 'flappy_provider.dart';
import 'flappy_styles.dart';
import 'package:we_play/core/providers/coin_provider.dart';
import 'package:we_play/core/providers/user_stats_provider.dart';
import 'package:we_play/core/providers/ad_provider.dart';

// ─────────────────────────────────────────────
//  FLAPPY BIRD SCREEN
// ─────────────────────────────────────────────
class FlappyBirdScreen extends ConsumerStatefulWidget {
  const FlappyBirdScreen({super.key});

  @override
  ConsumerState<FlappyBirdScreen> createState() => _FlappyBirdScreenState();
}

class _FlappyBirdScreenState extends ConsumerState<FlappyBirdScreen> {
  late FlappyGame _game;
  bool _started        = false;
  bool _showingGameOver= false;

  @override
  void initState() {
    super.initState();
    _game = FlappyGame(notifier: ref.read(flappyProvider.notifier));
  }

  void _startGame() {
    setState(() {
      _started         = true;
      _showingGameOver = false;
    });
    _game.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flappyProvider);

    // Game over trigger
    if (state.status == FlappyStatus.dead &&
        _started &&
        !_showingGameOver) {
      _showingGameOver = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _showGameOver(context, state);
      });
    }

    return Scaffold(
      backgroundColor: FlappyColors.background,
      body: Stack(
        children: [
          // ── Flame canvas ──────────────────
          GestureDetector(
            onTapDown: (_) {
              if (_started &&
                  state.status == FlappyStatus.playing) {
                // Tap is handled by Flame TapCallbacks
              }
            },
            child: GameWidget(game: _game),
          ),

          // ── Score HUD ─────────────────────
          if (_started && state.status == FlappyStatus.playing)
            SafeArea(
              child: _buildScoreHUD(state),
            ),

          // ── Back button ───────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: FlappyColors.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: FlappyColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: FlappyColors.textSecondary, size: 16),
                ),
              ),
            ),
          ),

          // ── Start overlay ─────────────────
          if (!_started) _buildStartOverlay(state),
        ],
      ),
    );
  }

  // ── Score HUD ─────────────────────────────
  Widget _buildScoreHUD(FlappyState state) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.score.toString(),
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: FlappyColors.textPrimary,
                shadows: [
                  Shadow(
                      color: FlappyColors.primary.withValues(alpha: 0.5),
                      blurRadius: 20),
                ],
              ),
            ),
            if (state.coins > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${state.coins}',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: FlappyColors.warn,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Start Overlay ─────────────────────────
  Widget _buildStartOverlay(FlappyState state) {
    return Container(
      color: FlappyColors.background.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐦', style: TextStyle(fontSize: 56))
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.3)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(end: -10, duration: 800.ms, curve: Curves.easeInOut),
            const SizedBox(height: 16),
            Text(
              'FLAPPY BIRD',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: FlappyColors.primary,
                letterSpacing: 2,
                shadows: [Shadow(
                    color: FlappyColors.primary.withValues(alpha: 0.6),
                    blurRadius: 20)],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 12),
            const Text(
              'tap anywhere to flap\ndon\'t hit the pipes!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: FlappyColors.textSecondary,
                height: 1.6,
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              'coins every ${FlappyConst.coinEvery} pipes',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                color: FlappyColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ).animate(delay: 280.ms).fadeIn(duration: 400.ms),
            if (state.bestScore > 0) ...[
              const SizedBox(height: 6),
              Text(
                'best: ${state.bestScore}',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 13,
                  color: FlappyColors.accent,
                ),
              ).animate(delay: 320.ms).fadeIn(duration: 400.ms),
            ],
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _GlowButton(
                label: 'tap to fly',
                color: FlappyColors.primary,
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

  // ── Game Over ─────────────────────────────
  void _showGameOver(BuildContext ctx, FlappyState state) {
    if (!mounted) return;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _GameOverSheet(
        score:     state.score,
        best:      state.bestScore,
        coins:     state.coins,
        isNewBest: state.score >= state.bestScore && state.score > 0,
        onAgain: () {
          Navigator.pop(ctx);
          setState(() {
            _showingGameOver = false;
          });
          _startGame();
        },
        onHome: () {
          Navigator.pop(ctx);
          Navigator.maybePop(ctx);
        },
      ),
    );

    // Award coins and track games played
    if (state.coins > 0) {
      ref.read(coinNotifierProvider.notifier).earnCoins(state.coins);
    }
    ref.read(userStatsProvider.notifier).incrementGamesPlayed();
    ref.read(adServiceProvider).showInterstitialIfReady();
  }
}

// ─────────────────────────────────────────────
//  GAME OVER SHEET
// ─────────────────────────────────────────────
class _GameOverSheet extends StatelessWidget {
  final int  score, best, coins;
  final bool isNewBest;
  final VoidCallback onAgain, onHome;

  const _GameOverSheet({
    required this.score,
    required this.best,
    required this.coins,
    required this.isNewBest,
    required this.onAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FlappyColors.surface,
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
              color: FlappyColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            isNewBest ? 'new high score! 🔥' : 'rip the bird 😭',
            style: const TextStyle(
              fontSize: 13,
              color: FlappyColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'game over',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: FlappyColors.energy,
              shadows: [Shadow(
                  color: FlappyColors.energy.withValues(alpha: 0.5),
                  blurRadius: 16)],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('SCORE', score.toString(), FlappyColors.primary),
              _stat('BEST',  best.toString(),  FlappyColors.accent),
              _stat('COINS', '+$coins',        const Color(0xFFFFD740)),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 32),

          _GlowButton(
            label: 'fly again',
            color: FlappyColors.primary,
            onTap: onAgain,
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 12),

          TextButton(
            onPressed: onHome,
            child: const Text(
              'back to lobby',
              style: TextStyle(
                  color: FlappyColors.textSecondary, fontSize: 14),
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
            color: FlappyColors.textSecondary,
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
              colors: [color, color.withValues(alpha: 0.7)]),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 2),
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
