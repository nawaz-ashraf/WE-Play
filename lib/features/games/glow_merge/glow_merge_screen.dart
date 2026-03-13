import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glow_merge_logic.dart';
import 'glow_merge_provider.dart';
import 'glow_merge_styles.dart';

// ─────────────────────────────────────────────
//  MAIN GAME SCREEN
// ─────────────────────────────────────────────
class GlowMergeScreen extends ConsumerStatefulWidget {
  const GlowMergeScreen({super.key});

  @override
  ConsumerState<GlowMergeScreen> createState() => _GlowMergeScreenState();
}

class _GlowMergeScreenState extends ConsumerState<GlowMergeScreen>
    with TickerProviderStateMixin {
  Offset? _dragStart;
  static const double _swipeThreshold = 30.0;

  // Score animation
  late AnimationController _scoreController;
  late Animation<double> _scoreAnim;
  int _displayedScore = 0;
  int _targetScore = 0;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scoreAnim = CurvedAnimation(parent: _scoreController, curve: Curves.easeOut);
    _scoreAnim.addListener(() {
      setState(() {
        _displayedScore = (_targetScore * _scoreAnim.value).toInt();
      });
    });

    // Auto-start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(glowMergeProvider.notifier).startGame();
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  void _animateScore(int to) {
    _targetScore = to;
    _displayedScore = 0;
    _scoreController.forward(from: 0);
  }

  void _handleSwipe(SwipeDirection dir) {
    HapticFeedback.lightImpact();
    final before = ref.read(glowMergeProvider).score;
    ref.read(glowMergeProvider.notifier).swipe(dir);
    final after = ref.read(glowMergeProvider).score;
    if (after > before) _animateScore(after);

    // Clear merge events after a frame so animations trigger once
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) ref.read(glowMergeProvider.notifier).resetMergeEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(glowMergeProvider);

    // Game over overlay
    if (state.status == GameStatus.over) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOver(context, state);
      });
    }

    return Scaffold(
      backgroundColor: GlowColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(state),
            const SizedBox(height: 16),
            _buildScoreRow(state),
            const SizedBox(height: 24),
            Expanded(child: _buildGrid(state)),
            const SizedBox(height: 16),
            _buildHint(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────
  Widget _buildHeader(GlowMergeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: GlowColors.textSecondary, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
          Text(
            'GLOW MERGE',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GlowColors.primary,
              letterSpacing: 2,
              shadows: [Shadow(color: GlowColors.primary.withOpacity(0.5), blurRadius: 12)],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: GlowColors.textSecondary, size: 22),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(glowMergeProvider.notifier).startGame();
            },
          ),
        ],
      ),
    );
  }

  // ── Score Row ─────────────────────────────
  Widget _buildScoreRow(GlowMergeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _scoreCard('SCORE', state.score, GlowColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _scoreCard('BEST', state.bestScore, GlowColors.accent)),
          const SizedBox(width: 12),
          Expanded(child: _scoreCard('COINS', state.coins, const Color(0xFFFFD740))),
        ],
      ),
    );
  }

  Widget _scoreCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: GlowColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'Orbitron',
                color: GlowColors.textSecondary,
                letterSpacing: 1.5,
              )),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid ──────────────────────────────────
  Widget _buildGrid(GlowMergeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onPanStart: (d) => _dragStart = d.globalPosition,
        onPanEnd: (d) {
          if (_dragStart == null) return;
          final delta = d.velocity.pixelsPerSecond;
          final dx = delta.dx.abs();
          final dy = delta.dy.abs();
          if (dx < _swipeThreshold && dy < _swipeThreshold) return;
          if (dx > dy) {
            _handleSwipe(delta.dx > 0 ? SwipeDirection.right : SwipeDirection.left);
          } else {
            _handleSwipe(delta.dy > 0 ? SwipeDirection.down : SwipeDirection.up);
          }
          _dragStart = null;
        },
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GlowColors.gridBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GlowColors.primary.withOpacity(0.2)),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: GlowMergeEngine.size,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: GlowMergeEngine.size * GlowMergeEngine.size,
              itemBuilder: (ctx, i) {
                final r = i ~/ GlowMergeEngine.size;
                final c = i % GlowMergeEngine.size;
                final blob = state.grid[r][c];
                final isMerged = state.lastMerges
                    .any((m) => m.row == r && m.col == c);
                return _BlobCell(
                  blob: blob,
                  isMerged: isMerged,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Hint ──────────────────────────────────
  Widget _buildHint() {
    return const Text(
      'swipe to merge',
      style: TextStyle(
        fontSize: 12,
        color: GlowColors.textSecondary,
        letterSpacing: 1,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  // ── Game Over sheet ───────────────────────
  void _showGameOver(BuildContext context, GlowMergeState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _GameOverSheet(
        score: state.score,
        coins: state.coins,
        bestScore: state.bestScore,
        onPlayAgain: () {
          Navigator.pop(context);
          ref.read(glowMergeProvider.notifier).startGame();
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.maybePop(context);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BLOB CELL WIDGET
// ─────────────────────────────────────────────
class _BlobCell extends StatelessWidget {
  final Blob? blob;
  final bool isMerged;

  const _BlobCell({this.blob, this.isMerged = false});

  @override
  Widget build(BuildContext context) {
    if (blob == null) {
      return Container(
        decoration: BoxDecoration(
          color: GlowColors.cellEmpty,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    final style = getBlobStyle(blob!.value);

    Widget cell = Container(
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: style.border.withOpacity(0.4),
            blurRadius: isMerged ? 16 : 6,
            spreadRadius: isMerged ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              style.label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: style.text,
              ),
            ),
          ),
        ),
      ),
    );

    // Appear animation for new blobs
    cell = cell
        .animate(key: ValueKey(blob!.id))
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1, 1),
          duration: 220.ms,
          curve: Curves.elasticOut,
        );

    // Merge burst animation
    if (isMerged) {
      cell = cell
          .animate()
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.25, 1.25),
            duration: 120.ms,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            begin: const Offset(1.25, 1.25),
            end: const Offset(1.0, 1.0),
            duration: 180.ms,
            curve: Curves.elasticOut,
          )
          .shimmer(
            duration: 400.ms,
            color: style.border.withOpacity(0.8),
          );
    }

    return cell;
  }
}

// ─────────────────────────────────────────────
//  GAME OVER BOTTOM SHEET
// ─────────────────────────────────────────────
class _GameOverSheet extends StatelessWidget {
  final int score;
  final int coins;
  final int bestScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const _GameOverSheet({
    required this.score,
    required this.coins,
    required this.bestScore,
    required this.onPlayAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final isNewBest = score >= bestScore;

    return Container(
      decoration: const BoxDecoration(
        color: GlowColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: GlowColors.textSecondary.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Status text
          Text(
            isNewBest ? 'main character behavior 🔥' : 'no cap, so close 😭',
            style: const TextStyle(
              fontSize: 13,
              color: GlowColors.textSecondary,
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
              color: GlowColors.energy,
              shadows: [Shadow(color: GlowColors.energy.withOpacity(0.5), blurRadius: 16)],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 28),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statChip('SCORE', score.toString(), GlowColors.primary),
              _statChip('COINS', '+$coins', const Color(0xFFFFD740)),
              _statChip('BEST', bestScore.toString(), GlowColors.accent),
            ],
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 32),

          // Play again
          _GlowButton(
            label: 'play again',
            color: GlowColors.primary,
            onTap: onPlayAgain,
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 12),

          // Home
          TextButton(
            onPressed: onHome,
            child: const Text(
              'back to lobby',
              style: TextStyle(color: GlowColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: GlowColors.textSecondary,
            letterSpacing: 1.5,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE GLOW BUTTON
// ─────────────────────────────────────────────
class _GlowButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlowButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

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
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
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
