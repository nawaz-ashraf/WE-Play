import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'snake_game.dart';
import 'snake_provider.dart';
import 'snake_styles.dart';
import 'package:we_play/core/providers/coin_provider.dart';
import 'package:we_play/core/providers/user_stats_provider.dart';

// ─────────────────────────────────────────────
//  SNAKE SCREEN
// ─────────────────────────────────────────────
class SnakeGameScreen extends ConsumerStatefulWidget {
  const SnakeGameScreen({super.key});

  @override
  ConsumerState<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends ConsumerState<SnakeGameScreen> {
  late SnakeGame _game;
  bool _started        = false;
  bool _showingGameOver= false;

  @override
  void initState() {
    super.initState();
    _game = SnakeGame(notifier: ref.read(snakeProvider.notifier));
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
    final state = ref.watch(snakeProvider);

    // Game over
    if (state.status == SnakeStatus.dead &&
        _started &&
        !_showingGameOver) {
      _showingGameOver = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _showGameOver(context, state);
      });
    }

    return Scaffold(
      backgroundColor: SnakeColors.background,
      body: Stack(
        children: [
          // ── Flame canvas ──────────────────
          GameWidget(game: _game),

          // ── HUD ───────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(state),
                const Spacer(),
                if (_started) _buildDPad(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Speed badge ───────────────────
          if (_started)
            Positioned(
              right: 14,
              top: MediaQuery.of(context).padding.top + 64,
              child: _SpeedBadge(speed: state.speed),
            ),

          // ── Start overlay ─────────────────
          if (!_started) _buildStartOverlay(state),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────
  Widget _buildTopBar(SnakeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: SnakeColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 10),

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
                    color: SnakeColors.textPrimary,
                  ),
                ),
                const Text('score',
                    style: TextStyle(
                      fontSize: 10,
                      color: SnakeColors.textSecondary,
                      letterSpacing: 1.5,
                    )),
              ],
            ),
          ),

          // Length
          _statChip(
              '🐍 ${state.length}', SnakeColors.primary),
          const SizedBox(width: 8),

          // Coins
          _statChip('🪙 ${state.coins}', SnakeColors.warn),
          const SizedBox(width: 8),

          // Best
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(state.bestScore.toString(),
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SnakeColors.accent,
                  )),
              const Text('best',
                  style: TextStyle(
                    fontSize: 9,
                    color: SnakeColors.textSecondary,
                    letterSpacing: 1.5,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          )),
    );
  }

  // ── D-Pad ─────────────────────────────────
  Widget _buildDPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left
          _DPadBtn(
            icon: Icons.keyboard_arrow_left_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              _game.swipeLeft();
            },
          ),
          const SizedBox(width: 4),
          // Up / Down column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DPadBtn(
                icon: Icons.keyboard_arrow_up_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _game.swipeUp();
                },
              ),
              const SizedBox(height: 4),
              _DPadBtn(
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _game.swipeDown();
                },
              ),
            ],
          ),
          const SizedBox(width: 4),
          // Right
          _DPadBtn(
            icon: Icons.keyboard_arrow_right_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              _game.swipeRight();
            },
          ),
        ],
      ),
    );
  }

  // ── Start Overlay ─────────────────────────
  Widget _buildStartOverlay(SnakeState state) {
    return Container(
      color: SnakeColors.background.withOpacity(0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐍', style: TextStyle(fontSize: 60))
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.3),
            const SizedBox(height: 16),
            Text(
              'SNAKE',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: SnakeColors.primary,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                      color: SnakeColors.primary.withOpacity(0.6),
                      blurRadius: 24),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 12),
            const Text(
              'swipe or use D-pad to move\neat food to grow — don\'t hit yourself!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: SnakeColors.textSecondary,
                height: 1.6,
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 12),

            // Food legend
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _foodLegend('🍎', '+${SnakeConst.scoreApple}', SnakeColors.foodApple),
                const SizedBox(width: 16),
                _foodLegend('⭐', '+${SnakeConst.scoreStar}', SnakeColors.foodStar),
                const SizedBox(width: 16),
                _foodLegend('💎', '+${SnakeConst.scoreGem}', SnakeColors.foodGem),
              ],
            ).animate(delay: 280.ms).fadeIn(duration: 400.ms),

            if (state.bestScore > 0) ...[
              const SizedBox(height: 10),
              Text(
                'best: ${state.bestScore}',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 13,
                  color: SnakeColors.accent,
                ),
              ).animate(delay: 330.ms).fadeIn(duration: 400.ms),
            ],

            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _GlowButton(
                label: "let's slither",
                color: SnakeColors.primary,
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

  Widget _foodLegend(String emoji, String pts, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 4),
      Text(pts,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          )),
    ],
  );

  // ── Game Over ─────────────────────────────
  void _showGameOver(BuildContext ctx, SnakeState state) {
    if (!mounted) return;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _GameOverSheet(
        score:     state.score,
        best:      state.bestScore,
        coins:     state.coins,
        length:    state.length,
        isNewBest: state.score >= state.bestScore && state.score > 0,
        onAgain: () {
          Navigator.pop(ctx);
          setState(() {
            _showingGameOver = false;
            _game = SnakeGame(
                notifier: ref.read(snakeProvider.notifier));
          });
          Future.delayed(
              const Duration(milliseconds: 100), _startGame);
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
  }
}

// ─────────────────────────────────────────────
//  SPEED BADGE
// ─────────────────────────────────────────────
class _SpeedBadge extends StatelessWidget {
  final double speed;
  const _SpeedBadge({required this.speed});

  @override
  Widget build(BuildContext context) {
    final tier = speed < 9
        ? ('slow', SnakeColors.accent)
        : speed < 13
            ? ('fast', SnakeColors.warn)
            : ('MAX', SnakeColors.energy);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tier.$2.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tier.$2.withOpacity(0.4)),
      ),
      child: Text(
        tier.$1,
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 9,
          color: tier.$2,
          letterSpacing: 1,
        ),
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
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: SnakeColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: SnakeColors.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: SnakeColors.primary.withOpacity(0.1),
                blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: SnakeColors.primary, size: 30),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GAME OVER SHEET
// ─────────────────────────────────────────────
class _GameOverSheet extends StatelessWidget {
  final int  score, best, coins, length;
  final bool isNewBest;
  final VoidCallback onAgain, onHome;

  const _GameOverSheet({
    required this.score,
    required this.best,
    required this.coins,
    required this.length,
    required this.isNewBest,
    required this.onAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SnakeColors.surface,
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
              color: SnakeColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            isNewBest ? 'snakey legend 🐍🔥' : 'you hit yourself 💀',
            style: const TextStyle(
              fontSize: 13,
              color: SnakeColors.textSecondary,
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
              color: SnakeColors.energy,
              shadows: [
                Shadow(
                    color: SnakeColors.energy.withOpacity(0.5),
                    blurRadius: 16)
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('SCORE',  score.toString(),  SnakeColors.primary),
              _stat('LENGTH', '$length 🐍',      SnakeColors.accent),
              _stat('COINS',  '+$coins',         SnakeColors.warn),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          if (isNewBest) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: SnakeColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: SnakeColors.accent.withOpacity(0.4)),
              ),
              child: Text(
                '🏆 new best: $best',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 13,
                  color: SnakeColors.accent,
                ),
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          ],

          const SizedBox(height: 28),

          _GlowButton(
            label: 'play again',
            color: SnakeColors.primary,
            onTap: onAgain,
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 12),

          TextButton(
            onPressed: onHome,
            child: const Text('back to lobby',
                style: TextStyle(
                    color: SnakeColors.textSecondary, fontSize: 14)),
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
            color: SnakeColors.textSecondary,
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
  const _GlowButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.45),
                blurRadius: 20,
                spreadRadius: 2)
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              )),
        ),
      ),
    );
  }
}
