import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'snack_game.dart';
import 'snack_provider.dart';
import 'snack_styles.dart';
import '../glow_merge/coin_service.dart';

// ─────────────────────────────────────────────
//  SNACK STACKERS SCREEN
// ─────────────────────────────────────────────
class SnackStackersScreen extends ConsumerStatefulWidget {
  const SnackStackersScreen({super.key});

  @override
  ConsumerState<SnackStackersScreen> createState() =>
      _SnackStackersScreenState();
}

class _SnackStackersScreenState extends ConsumerState<SnackStackersScreen> {
  late SnackGame _game;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _game = SnackGame(notifier: ref.read(snackProvider.notifier));
  }

  void _startGame() {
    setState(() => _started = true);
    _game.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(snackProvider);

    if (state.status == StackGameStatus.over && _started) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOver(context, state);
      });
    }

    return Scaffold(
      backgroundColor: StackColors.background,
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
                if (state.wobbling && _started) _buildWobbleWarning(),
                _buildBottomHUD(state),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Start overlay ─────────────────
          if (!_started) _buildStartOverlay(),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────
  Widget _buildTopBar(SnackState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: StackColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.score.toStringAsFixed(1)}m',
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: StackColors.textPrimary,
                  ),
                ),
                const Text(
                  'tower height',
                  style: TextStyle(
                    fontSize: 10,
                    color: StackColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Timer
          _TimerChip(timeLeft: state.timeLeft),
          const SizedBox(width: 10),
          // Coins
          _CoinChip(coins: state.coins),
        ],
      ),
    );
  }

  // ── Wobble Warning ────────────────────────
  Widget _buildWobbleWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: StackColors.energy.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StackColors.energy.withOpacity(0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚠️', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          Text(
            'tower wobbling — drop carefully!',
            style: TextStyle(
              fontSize: 12,
              color: StackColors.energy,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 400.ms)
        .then()
        .fadeOut(duration: 400.ms);
  }

  // ── Bottom HUD ────────────────────────────
  Widget _buildBottomHUD(SnackState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items dropped
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.itemsDropped}',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: StackColors.primary,
                ),
              ),
              const Text(
                'dropped',
                style: TextStyle(
                    fontSize: 10,
                    color: StackColors.textSecondary,
                    letterSpacing: 1),
              ),
            ],
          ),

          // Tap hint
          const Text(
            'tap to drop',
            style: TextStyle(
              fontSize: 12,
              color: StackColors.textSecondary,
              letterSpacing: 1,
              fontStyle: FontStyle.italic,
            ),
          ),

          // Next item preview
          if (state.nextItem != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  state.nextItem!.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                Text(
                  'next: ${state.nextItem!.name.toLowerCase()}',
                  style: const TextStyle(
                      fontSize: 10,
                      color: StackColors.textSecondary,
                      letterSpacing: 1),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Start Overlay ─────────────────────────
  Widget _buildStartOverlay() {
    return Container(
      color: StackColors.background.withOpacity(0.88),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🍔🍕🍣',
              style: TextStyle(fontSize: 48),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3),
            const SizedBox(height: 16),
            Text(
              'SNACK STACKERS',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: StackColors.primary,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                      color: StackColors.primary.withOpacity(0.6),
                      blurRadius: 20),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 12),
            const Text(
              'tap the screen to drop food\nbuild the tallest tower!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: StackColors.textSecondary,
                height: 1.6,
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 40),
            _GlowButton(
              label: "let's stack",
              color: StackColors.primary,
              onTap: () {
                HapticFeedback.heavyImpact();
                _startGame();
              },
            ).animate(delay: 350.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }

  // ── Game Over ─────────────────────────────
  Future<void> _showGameOver(BuildContext ctx, SnackState state) async {
    await showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _GameOverSheet(
        score:  state.score,
        coins:  state.coins,
        best:   state.bestScore,
        items:  state.itemsDropped,
        onAgain: () {
          Navigator.pop(ctx);
          setState(() {
            _started = false;
            _game = SnackGame(notifier: ref.read(snackProvider.notifier));
          });
        },
        onHome: () {
          Navigator.pop(ctx);
          Navigator.maybePop(ctx);
        },
      ),
    );

    // Award coins after sheet shown
    final coinService = CoinService();
    await coinService.awardCoins(state.coins);
  }
}

// ─────────────────────────────────────────────
//  TIMER CHIP
// ─────────────────────────────────────────────
class _TimerChip extends StatelessWidget {
  final double timeLeft;

  const _TimerChip({required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final isLow = timeLeft < 10;
    final color = isLow ? StackColors.energy : StackColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
//  COIN CHIP
// ─────────────────────────────────────────────
class _CoinChip extends StatelessWidget {
  final int coins;

  const _CoinChip({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD740).withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: const Color(0xFFFFD740).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFD740),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GAME OVER SHEET
// ─────────────────────────────────────────────
class _GameOverSheet extends StatelessWidget {
  final double score;
  final int coins;
  final double best;
  final int items;
  final VoidCallback onAgain;
  final VoidCallback onHome;

  const _GameOverSheet({
    required this.score,
    required this.coins,
    required this.best,
    required this.items,
    required this.onAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final isNewBest = score >= best && score > 0;

    return Container(
      decoration: const BoxDecoration(
        color: StackColors.surface,
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
              color: StackColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            isNewBest ? 'new tower record! 🏆' : 'the tower fell 😭',
            style: const TextStyle(
              fontSize: 13,
              color: StackColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'stack complete',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: StackColors.primary,
              shadows: [Shadow(
                color: StackColors.primary.withOpacity(0.5),
                blurRadius: 16,
              )],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('HEIGHT',   '${score.toStringAsFixed(1)}m',  StackColors.primary),
              _stat('ITEMS',    '$items',       StackColors.accent),
              _stat('COINS',    '+$coins',      const Color(0xFFFFD740)),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 32),

          _GlowButton(
            label: 'stack again',
            color: StackColors.primary,
            onTap: onAgain,
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 12),

          TextButton(
            onPressed: onHome,
            child: const Text(
              'back to lobby',
              style: TextStyle(color: StackColors.textSecondary, fontSize: 14),
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
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          )),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(
            fontSize: 10,
            color: StackColors.textSecondary,
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
