import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'memory_provider.dart';
import 'memory_styles.dart';
import 'memory_widgets.dart';
import 'package:we_play/core/providers/coin_provider.dart';
import 'package:we_play/core/providers/user_stats_provider.dart';
import 'package:we_play/core/providers/ad_provider.dart';

// ─────────────────────────────────────────────
//  MEMORY PUZZLE SCREEN
// ─────────────────────────────────────────────
class MemoryPuzzleScreen extends ConsumerStatefulWidget {
  const MemoryPuzzleScreen({super.key});

  @override
  ConsumerState<MemoryPuzzleScreen> createState() =>
      _MemoryPuzzleScreenState();
}

class _MemoryPuzzleScreenState extends ConsumerState<MemoryPuzzleScreen> {
  bool _started            = false;
  bool _showingComplete    = false;
  Set<int> _mismatchedIds  = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryProvider);

    // Game complete trigger
    if (state.status == MemoryStatus.complete &&
        _started &&
        !_showingComplete) {
      _showingComplete = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showComplete(context, state);
      });
    }

    return Scaffold(
      backgroundColor: MemoryColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(state),
            if (_started) ...[
              _buildProgressRow(state),
              const SizedBox(height: 8),
              Expanded(child: _buildGrid(state)),
              _buildBottomHUD(state),
              const SizedBox(height: 16),
            ],
            if (!_started) Expanded(child: _buildStartScreen()),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────
  Widget _buildTopBar(MemoryState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: MemoryColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'MEMORY PUZZLE',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MemoryColors.primary,
                letterSpacing: 1.5,
                shadows: [Shadow(
                    color: MemoryColors.primary.withOpacity(0.5),
                    blurRadius: 12)],
              ),
            ),
          ),
          if (_started) ...[
            MemoryTimer(
              timeLeft: state.timeLeft,
              total: MemoryConst.timeLimits[state.difficulty]!.toDouble(),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _started         = false;
                  _showingComplete = false;
                  _mismatchedIds   = {};
                });
                ref.read(memoryProvider.notifier)
                    .startGame(state.difficulty);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: MemoryColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: MemoryColors.primary.withOpacity(0.3)),
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: MemoryColors.textSecondary, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Progress row ──────────────────────────
  Widget _buildProgressRow(MemoryState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.matchedPairs}/${state.totalPairs} pairs',
                style: const TextStyle(
                  fontSize: 11,
                  color: MemoryColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${state.moves} moves',
                style: const TextStyle(
                  fontSize: 11,
                  color: MemoryColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          MemoryProgressBar(
            progress: state.progress,
            color: state.difficulty.color,
          ),
        ],
      ),
    );
  }

  // ── Grid ──────────────────────────────────
  Widget _buildGrid(MemoryState state) {
    if (state.cards.isEmpty) return const SizedBox.shrink();

    final gridSize = MemoryConst.gridSizes[state.difficulty]!;
    final cols     = gridSize.cols;
    final rows     = gridSize.rows;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final gap  = MemoryConst.cardGap;
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;

          // Ideal card size based on full width
          final idealCardW = (maxW - gap * (cols - 1)) / cols;
          final idealCardH = idealCardW / MemoryConst.cardAspect;
          final totalIdealH = idealCardH * rows + gap * (rows - 1);

          double gridWidth = maxW;

          // If standard width makes it too tall, restrict by height instead
          // Subtract a small buffer (e.g., 8 px) to ensure it fits comfortably
          if (totalIdealH > maxH - 8) {
            final cardH = (maxH - 8 - gap * (rows - 1)) / rows;
            final cardW = cardH * MemoryConst.cardAspect;
            gridWidth = cardW * cols + gap * (cols - 1);
          }

          return Center(
            child: SizedBox(
              width: gridWidth,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:   cols,
                  crossAxisSpacing: gap,
                  mainAxisSpacing:  gap,
                  childAspectRatio: MemoryConst.cardAspect,
                ),
                itemCount: state.cards.length,
                itemBuilder: (ctx, i) {
                  final card          = state.cards[i];
                  final isMismatched  = _mismatchedIds.contains(card.id);

                  return MemoryCardWidget(
                    key:             ValueKey('card_${card.id}_${card.isFaceUp}_${card.isMatched}'),
                    card:            card,
                    justMismatched:  isMismatched,
                    onTap: () => _onCardTap(i, state),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCardTap(int index, MemoryState state) {
    if (state.isFlipping) return;
    HapticFeedback.selectionClick();

    final prevFaceUp = Set<int>.from(
        state.faceUpIndices.map((i) => state.cards[i].id));

    ref.read(memoryProvider.notifier).flipCard(index);

    final newState = ref.read(memoryProvider);

    // Detect mismatch — two cards were face up, now being flipped back
    if (newState.isFlipping) {
      final mismatchedIds = newState.faceUpIndices
          .map((i) => newState.cards[i].id)
          .toSet();
      setState(() => _mismatchedIds = mismatchedIds);
      HapticFeedback.lightImpact();

      Future.delayed(
        Duration(
            milliseconds:
                (MemoryConst.flipBackDelay * 1000).toInt()),
        () {
          if (mounted) setState(() => _mismatchedIds = {});
        },
      );
    } else {
      setState(() => _mismatchedIds = {});
    }

    // Match haptic
    if (newState.matchedPairs > state.matchedPairs) {
      HapticFeedback.mediumImpact();
    }
  }

  // ── Bottom HUD ────────────────────────────
  Widget _buildBottomHUD(MemoryState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _hudChip('SCORE', state.score.toString(), MemoryColors.primary),
          _hudChip('COINS', '+${state.coins}',      MemoryColors.warn),
          _hudChip('BEST',  state.bestScore.toString(), MemoryColors.accent),
          _hudChip(
            state.difficulty.label.toUpperCase(),
            '',
            state.difficulty.color,
            isLabel: true,
          ),
        ],
      ),
    );
  }

  Widget _hudChip(String label, String value, Color color,
      {bool isLabel = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLabel)
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        Text(
          label,
          style: TextStyle(
            fontSize: isLabel ? 13 : 9,
            color: isLabel ? color : MemoryColors.textSecondary,
            letterSpacing: 1.5,
            fontFamily: 'Orbitron',
            fontWeight: isLabel ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── Start Screen ──────────────────────────
  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🃏', style: TextStyle(fontSize: 60))
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.3),
          const SizedBox(height: 16),
          const Text(
            'MEMORY PUZZLE',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MemoryColors.primary,
              letterSpacing: 2,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
          const SizedBox(height: 8),
          const Text(
            'flip cards to find matching pairs\nbefore time runs out!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: MemoryColors.textSecondary,
              height: 1.6,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
          const SizedBox(height: 32),

          // Difficulty picker
          const Text(
            'PICK DIFFICULTY',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              color: MemoryColors.textSecondary,
              letterSpacing: 2,
            ),
          ).animate(delay: 280.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: MemoryDifficulty.values.map((d) {
              final gridSize = MemoryConst.gridSizes[d]!;
              final pairs =
                  (gridSize.cols * gridSize.rows) ~/ 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _DifficultyCard(
                  difficulty: d,
                  pairs:      pairs,
                  timeLimit:  MemoryConst.timeLimits[d]!,
                  onTap: () => _startGame(d),
                ),
              );
            }).toList(),
          ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
        ],
      ),
    );
  }

  void _startGame(MemoryDifficulty difficulty) {
    HapticFeedback.heavyImpact();
    setState(() {
      _started         = true;
      _showingComplete = false;
      _mismatchedIds   = {};
    });
    ref.read(memoryProvider.notifier).startGame(difficulty);
  }

  // ── Game Complete ─────────────────────────
  void _showComplete(BuildContext ctx, MemoryState state) {
    if (!mounted) return;
    final timeLeft = state.timeLeft;
    final won      = state.matchedPairs >= state.totalPairs;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _CompleteSheet(
        won:      won,
        score:    state.score,
        coins:    state.coins,
        moves:    state.moves,
        best:     state.bestScore,
        timeLeft: timeLeft,
        onAgain: () {
          Navigator.pop(ctx);
          setState(() {
            _started         = false;
            _showingComplete = false;
            _mismatchedIds   = {};
          });
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
//  DIFFICULTY CARD
// ─────────────────────────────────────────────
class _DifficultyCard extends StatelessWidget {
  final MemoryDifficulty difficulty;
  final int pairs;
  final int timeLimit;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.pairs,
    required this.timeLimit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = difficulty.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              difficulty.label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$pairs pairs',
              style: const TextStyle(
                fontSize: 12,
                color: MemoryColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${timeLimit}s',
              style: const TextStyle(
                fontSize: 11,
                color: MemoryColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  COMPLETE SHEET
// ─────────────────────────────────────────────
class _CompleteSheet extends StatelessWidget {
  final bool   won;
  final int    score, coins, moves, best;
  final double timeLeft;
  final VoidCallback onAgain, onHome;

  const _CompleteSheet({
    required this.won,
    required this.score,
    required this.coins,
    required this.moves,
    required this.best,
    required this.timeLeft,
    required this.onAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final color = won ? MemoryColors.accent : MemoryColors.primary;

    return Container(
      decoration: const BoxDecoration(
        color: MemoryColors.surface,
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
              color: MemoryColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            won ? 'big brain energy 🧠' : 'time\'s up! so close 😭',
            style: const TextStyle(
              fontSize: 13,
              color: MemoryColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            won ? 'all matched!' : 'time\'s up',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              shadows: [
                Shadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 16),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('SCORE', score.toString(),  MemoryColors.primary),
              _stat('MOVES', moves.toString(),  MemoryColors.purple),
              _stat('COINS', '+$coins',         MemoryColors.warn),
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
            child: const Text(
              'back to lobby',
              style: TextStyle(
                  color: MemoryColors.textSecondary, fontSize: 14),
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
            color: MemoryColors.textSecondary,
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
          gradient:
              LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.45),
                blurRadius: 20,
                spreadRadius: 2)
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
