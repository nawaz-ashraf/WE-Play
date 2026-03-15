import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'flick_game.dart';
import 'flick_provider.dart';
import 'flick_styles.dart';

// ─────────────────────────────────────────────
//  FLICK ROYALE SCREEN
// ─────────────────────────────────────────────
class FlickRoyaleScreen extends ConsumerStatefulWidget {
  const FlickRoyaleScreen({super.key});

  @override
  ConsumerState<FlickRoyaleScreen> createState() => _FlickRoyaleScreenState();
}

class _FlickRoyaleScreenState extends ConsumerState<FlickRoyaleScreen> {
  late FlickGame _game;
  bool _started         = false;
  bool _showingRoundEnd = false;
  bool _showingMatchEnd = false;

  @override
  void initState() {
    super.initState();
    _game = FlickGame(notifier: ref.read(flickProvider.notifier));
  }

  void _startMatch() {
    setState(() => _started = true);
    _game.startMatch();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flickProvider);

    // Round over
    if (state.status == FlickStatus.roundOver &&
        _started &&
        !_showingRoundEnd) {
      _showingRoundEnd = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRoundOver(context, state);
      });
    }

    // Match over
    if (state.status == FlickStatus.matchOver && _started && !_showingMatchEnd) {
      _showingMatchEnd = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMatchOver(context, state);
      });
    }

    return Scaffold(
      backgroundColor: FlickColors.background,
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
                _buildPuckRow(state),
                const SizedBox(height: 20),
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
  Widget _buildTopBar(FlickState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: FlickColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 10),

          // Round indicator
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(FlickConst.rounds, (i) {
                final won = i < state.playerRoundWins;
                final lost = i < state.aiRoundWins;
                return Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: won
                        ? FlickColors.playerPuck
                        : lost
                            ? FlickColors.aiPuck
                            : FlickColors.surface,
                    border: Border.all(
                      color: i == state.round - 1
                          ? FlickColors.textPrimary.withOpacity(0.5)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      won ? '✓' : lost ? '✗' : '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: won || lost
                            ? Colors.white
                            : FlickColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Timer
          _TimerRing(
              timeLeft: state.timeLeft,
              total: FlickConst.roundSeconds),
          const SizedBox(width: 8),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(state.score.toString(),
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: FlickColors.textPrimary,
                  )),
              const Text('score',
                  style: TextStyle(
                    fontSize: 9,
                    color: FlickColors.textSecondary,
                    letterSpacing: 1.5,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ── Puck Row ──────────────────────────────
  Widget _buildPuckRow(FlickState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Player pucks
          Row(
            children: List.generate(FlickConst.pucksPerSide, (i) {
              final active = i < state.playerPucksLeft;
              return Container(
                width: 16, height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? FlickColors.playerPuck
                      : FlickColors.playerPuck.withOpacity(0.15),
                  boxShadow: active
                      ? [BoxShadow(
                          color: FlickColors.playerPuck.withOpacity(0.5),
                          blurRadius: 8)]
                      : null,
                ),
              );
            }),
          ),

          const Text('VS',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                color: FlickColors.textSecondary,
                letterSpacing: 2,
              )),

          // AI pucks
          Row(
            children: List.generate(FlickConst.pucksPerSide, (i) {
              final active = i < state.aiPucksLeft;
              return Container(
                width: 16, height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? FlickColors.aiPuck
                      : FlickColors.aiPuck.withOpacity(0.15),
                  boxShadow: active
                      ? [BoxShadow(
                          color: FlickColors.aiPuck.withOpacity(0.5),
                          blurRadius: 8)]
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Start Overlay ─────────────────────────
  Widget _buildStartOverlay() {
    return Container(
      color: FlickColors.background.withOpacity(0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏒', style: TextStyle(fontSize: 52))
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.3),
            const SizedBox(height: 16),
            Text(
              'FLICK ROYALE',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: FlickColors.primary,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                      color: FlickColors.primary.withOpacity(0.6),
                      blurRadius: 24),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 12),
            const Text(
              'drag your pucks to flick them\nknock the opponent\'s off the arena',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: FlickColors.textSecondary,
                height: 1.6,
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _legend(FlickColors.playerPuck, 'your pucks'),
                const SizedBox(width: 20),
                _legend(FlickColors.aiPuck, 'AI pucks'),
              ],
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'best of ${FlickConst.rounds} rounds',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                color: FlickColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _GlowButton(
                label: 'start match',
                color: FlickColors.primary,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  _startMatch();
                },
              ),
            ).animate(delay: 450.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              fontSize: 12, color: FlickColors.textSecondary)),
    ],
  );

  // ── Round Over sheet ──────────────────────
  void _showRoundOver(BuildContext ctx, FlickState state) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _RoundOverSheet(
        round:  state.round - 1,
        winner: state.lastRoundWinner ?? RoundWinner.draw,
        pWins:  state.playerRoundWins,
        aWins:  state.aiRoundWins,
        onNext: () {
          Navigator.pop(ctx);
          setState(() => _showingRoundEnd = false);
          _game.startNextRound();
        },
      ),
    );
  }

  // ── Match Over sheet ──────────────────────
  void _showMatchOver(BuildContext ctx, FlickState state) {
    if (!mounted) return;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _MatchOverSheet(
        playerWon: state.playerWonMatch,
        score:     state.score,
        coins:     state.coins,
        pWins:     state.playerRoundWins,
        aWins:     state.aiRoundWins,
        onAgain: () {
          Navigator.pop(ctx);
          setState(() {
            _started         = false;
            _showingRoundEnd = false;
            _showingMatchEnd = false;
            _game = FlickGame(notifier: ref.read(flickProvider.notifier));
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
//  TIMER RING
// ─────────────────────────────────────────────
class _TimerRing extends StatelessWidget {
  final double timeLeft, total;
  const _TimerRing({required this.timeLeft, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = (timeLeft / total).clamp(0.0, 1.0);
    final isLow    = timeLeft < 6;
    final color    = isLow ? FlickColors.energy : FlickColors.primary;

    return SizedBox(
      width: 44, height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: FlickColors.surface,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(timeLeft.ceil().toString(),
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ROUND OVER SHEET
// ─────────────────────────────────────────────
class _RoundOverSheet extends StatelessWidget {
  final int         round;
  final RoundWinner winner;
  final int         pWins, aWins;
  final VoidCallback onNext;

  const _RoundOverSheet({
    required this.round,
    required this.winner,
    required this.pWins,
    required this.aWins,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final playerWon = winner == RoundWinner.player;
    final isDraw    = winner == RoundWinner.draw;
    final color = playerWon
        ? FlickColors.playerPuck
        : isDraw
            ? FlickColors.warn
            : FlickColors.aiPuck;

    return Container(
      decoration: const BoxDecoration(
        color: FlickColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: FlickColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text('round $round', style: const TextStyle(
            fontSize: 12, color: FlickColors.textSecondary,
            fontFamily: 'Orbitron', letterSpacing: 1.5,
          )),
          const SizedBox(height: 8),

          Text(
            playerWon ? 'you won it 🔥' : isDraw ? 'draw!' : 'AI takes it 😤',
            style: TextStyle(
              fontFamily: 'Orbitron', fontSize: 24,
              fontWeight: FontWeight.w700, color: color,
              shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 14)],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.3),

          const SizedBox(height: 20),

          // Score display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _roundDot(FlickColors.playerPuck, pWins),
              const SizedBox(width: 16),
              Text('rounds', style: const TextStyle(
                  fontSize: 12, color: FlickColors.textSecondary)),
              const SizedBox(width: 16),
              _roundDot(FlickColors.aiPuck, aWins),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 350.ms),

          const SizedBox(height: 28),

          _GlowButton(
            label: 'next round →',
            color: color,
            onTap: onNext,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _roundDot(Color color, int wins) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(FlickConst.rounds, (i) => Container(
      width: 16, height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: i < wins ? color : color.withOpacity(0.15),
      ),
    )),
  );
}

// ─────────────────────────────────────────────
//  MATCH OVER SHEET
// ─────────────────────────────────────────────
class _MatchOverSheet extends StatelessWidget {
  final bool playerWon;
  final int  score, coins, pWins, aWins;
  final VoidCallback onAgain, onHome;

  const _MatchOverSheet({
    required this.playerWon,
    required this.score,
    required this.coins,
    required this.pWins,
    required this.aWins,
    required this.onAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final color = playerWon ? FlickColors.accent : FlickColors.energy;

    return Container(
      decoration: const BoxDecoration(
        color: FlickColors.surface,
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
              color: FlickColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            playerWon ? 'that\'s W behaviour 🏆' : 'AI took the match 😭',
            style: const TextStyle(
              fontSize: 13, color: FlickColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            playerWon ? 'match winner' : 'match lost',
            style: TextStyle(
              fontFamily: 'Orbitron', fontSize: 28,
              fontWeight: FontWeight.w700, color: color,
              shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 18)],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 8),
          Text('$pWins – $aWins rounds',
              style: const TextStyle(
                  fontSize: 13, color: FlickColors.textSecondary)),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('SCORE',  score.toString(), FlickColors.primary),
              _stat('COINS',  '+$coins',        const Color(0xFFFFD740)),
              _stat('RESULT', playerWon ? 'WIN' : 'LOSS', color),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 32),

          _GlowButton(
            label: 'play again',
            color: color,
            onTap: onAgain,
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 12),

          TextButton(
            onPressed: onHome,
            child: const Text('back to lobby',
                style: TextStyle(
                    color: FlickColors.textSecondary, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(
    children: [
      Text(value, style: TextStyle(
        fontFamily: 'Orbitron', fontSize: 20,
        fontWeight: FontWeight.w700, color: color,
      )),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(
        fontSize: 10, color: FlickColors.textSecondary,
        letterSpacing: 1.5, fontFamily: 'Orbitron',
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
          boxShadow: [BoxShadow(
            color: color.withOpacity(0.45), blurRadius: 20, spreadRadius: 2)],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(
            fontFamily: 'Orbitron', fontSize: 15,
            fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1,
          )),
        ),
      ),
    );
  }
}
