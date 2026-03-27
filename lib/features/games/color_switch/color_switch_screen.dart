import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_switch_game.dart';
import 'color_switch_provider.dart';
import 'color_switch_styles.dart';
import 'package:we_play/core/providers/coin_provider.dart';
import 'package:we_play/core/providers/user_stats_provider.dart';

// ─────────────────────────────────────────────
//  COLOR SWITCH SCREEN
// ─────────────────────────────────────────────

class ColorSwitchScreen extends ConsumerStatefulWidget {
  const ColorSwitchScreen({super.key});
  @override
  ConsumerState<ColorSwitchScreen> createState() => _ColorSwitchScreenState();
}

class _ColorSwitchScreenState extends ConsumerState<ColorSwitchScreen>
    with SingleTickerProviderStateMixin {
  late ColorSwitchGame _game;
  bool _started = false;
  bool _showingGameOver = false;

  @override
  void initState() {
    super.initState();
    _game = ColorSwitchGame(notifier: ref.read(colorSwitchProvider.notifier));
  }

  void _startGame() {
    _game.startGame();
    setState(() {
      _started = true;
      _showingGameOver = false;
    });
  }

  void _retryGame() {
    setState(() {
      _showingGameOver = false;
      _game = ColorSwitchGame(notifier: ref.read(colorSwitchProvider.notifier));
    });
    Future.delayed(const Duration(milliseconds: 120), _startGame);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(colorSwitchProvider);

    // Game‑over trigger
    if (state.status == CSStatus.dead && _started && !_showingGameOver) {
      _showingGameOver = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _awardAndShowGameOver(state);
        });
      });
    }

    return Scaffold(
      backgroundColor: CSColors.background,
      body: Stack(
        children: [
          // ── Flame canvas ───────────────────
          GameWidget(game: _game),

          // ── HUD ────────────────────────────
          if (_started && state.status == CSStatus.playing) _buildHUD(state),

          // ── Start overlay ──────────────────
          if (!_started) _buildStartOverlay(),

          // ── Game‑over overlay ──────────────
          if (_showingGameOver && state.status == CSStatus.dead)
            _buildGameOverOverlay(state),
        ],
      ),
    );
  }

  // ── HUD ─────────────────────────────────────
  Widget _buildHUD(CSState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: CSColors.textSecondary,
                size: 22,
              ),
            ),
            const Spacer(),
            Column(
              children: [
                Text(
                  '${state.score}',
                  style: GoogleFonts.orbitron(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: CSColors.textPrimary,
                    shadows: [
                      Shadow(
                        color: state.ballColor.withAlpha(100),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                Text(
                  'best ${state.bestScore}',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: CSColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Ball colour indicator
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.ballColor,
                border: Border.all(color: Colors.white.withAlpha(80), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: state.ballColor.withAlpha(60),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Start Overlay ───────────────────────────
  Widget _buildStartOverlay() {
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: CSColors.overlay,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: CSColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 30),
                // 4‑colour mini icon
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(painter: _MiniWheelPainter()),
                ),
                const SizedBox(height: 20),
                Text(
                  'COLOR SWITCH',
                  style: GoogleFonts.orbitron(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: CSColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'match your color to pass through',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: CSColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: CSColors.gameColors.map((c) {
                    return Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        boxShadow: [
                          BoxShadow(color: c.withAlpha(60), blurRadius: 6),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                Text(
                  'TAP TO PLAY',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CSColors.accent,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Game‑Over Overlay ───────────────────────
  Widget _buildGameOverOverlay(CSState state) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: CSColors.overlay,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: CSColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: CSColors.accent.withAlpha(40),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(color: CSColors.accent.withAlpha(15), blurRadius: 40),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GAME OVER',
                  style: GoogleFonts.orbitron(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: CSColors.red,
                  ),
                ),
                const SizedBox(height: 24),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat('Score', '${state.score}', CSColors.accent),
                    _stat('Best', '${state.bestScore}', CSColors.green),
                    _stat('Coins', '+${state.coins}', CSColors.coin),
                  ],
                ),
                const SizedBox(height: 28),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: CSColors.textSecondary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          'HOME',
                          style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: CSColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _retryGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CSColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          'PLAY AGAIN',
                          style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: CSColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Award + show ────────────────────────────
  void _awardAndShowGameOver(CSState state) {
    if (state.coins > 0) {
      ref.read(coinNotifierProvider.notifier).earnCoins(state.coins);
    }
    ref.read(userStatsProvider.notifier).incrementGamesPlayed();
    // Overlay is already visible via _showingGameOver flag — just setState
    setState(() {});
  }
}

// ─────────────────────────────────────────────
//  Mini 4‑colour wheel for start screen
// ─────────────────────────────────────────────

class _MiniWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final inner = r * 0.55;

    canvas.save();
    canvas.translate(cx, cy);

    for (int i = 0; i < 4; i++) {
      final start = (i / 4) * 2 * 3.14159 - 3.14159 / 4;
      final sweep = 3.14159 / 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        start,
        sweep,
        true,
        Paint()..color = CSColors.gameColors[i],
      );
    }

    canvas.drawCircle(Offset.zero, inner, Paint()..color = CSColors.background);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
