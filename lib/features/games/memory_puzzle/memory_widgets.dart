import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'memory_styles.dart';

// ─────────────────────────────────────────────
//  MEMORY CARD WIDGET  — 3D flip animation
// ─────────────────────────────────────────────
class MemoryCardWidget extends StatefulWidget {
  final MemoryCard card;
  final VoidCallback onTap;
  final bool justMismatched; // triggers shake

  const MemoryCardWidget({
    super.key,
    required this.card,
    required this.onTap,
    this.justMismatched = false,
  });

  @override
  State<MemoryCardWidget> createState() => _MemoryCardWidgetState();
}

class _MemoryCardWidgetState extends State<MemoryCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double>   _flipAnim;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
    _showFront = widget.card.isFaceUp || widget.card.isMatched;
    if (_showFront) _flipCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(MemoryCardWidget old) {
    super.didUpdateWidget(old);
    final shouldShow = widget.card.isFaceUp || widget.card.isMatched;
    if (shouldShow != _showFront) {
      _showFront = shouldShow;
      if (_showFront) {
        _flipCtrl.forward();
      } else {
        _flipCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMatched = widget.card.isMatched;
    final isFaceUp  = widget.card.isFaceUp;

    Widget card = AnimatedBuilder(
      animation: _flipAnim,
      builder: (ctx, _) {
        final angle = _flipAnim.value * pi;
        final isFront = angle > pi / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle),
          child: isFront
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildFront(isMatched),
                )
              : _buildBack(),
        );
      },
    );

    // Shake on mismatch
    if (widget.justMismatched) {
      card = card
          .animate()
          .shakeX(amount: 4, duration: 400.ms, hz: 6);
    }

    // Match pulse
    if (isMatched) {
      card = card
          .animate()
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 200.ms,
            curve: Curves.elasticOut,
          )
          .then()
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1, 1),
            duration: 200.ms,
          );
    }

    return GestureDetector(
      onTap: isMatched ? null : widget.onTap,
      child: card,
    );
  }

  // ── Front face ────────────────────────────
  Widget _buildFront(bool isMatched) {
    final borderColor = isMatched
        ? MemoryColors.cardMatchEdge
        : MemoryColors.cardFlipEdge;
    final bgColor = isMatched
        ? MemoryColors.cardMatched
        : MemoryColors.cardFlipping;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(MemoryConst.cardRadius),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(isMatched ? 0.5 : 0.3),
            blurRadius: isMatched ? 16 : 8,
            spreadRadius: isMatched ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.card.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            if (isMatched) ...[
              const SizedBox(height: 4),
              Text(
                '✓',
                style: TextStyle(
                  fontSize: 12,
                  color: MemoryColors.cardMatchEdge,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Back face ─────────────────────────────
  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        color: MemoryColors.cardBack,
        borderRadius: BorderRadius.circular(MemoryConst.cardRadius),
        border: Border.all(
            color: MemoryColors.cardBackEdge, width: 1),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(36, 36),
          painter: _CardBackPainter(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CARD BACK PAINTER  — MiniPlay Hub logo pattern
// ─────────────────────────────────────────────
class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MemoryColors.cardBackEdge.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Diamond pattern
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.45;

    // Outer diamond
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    canvas.drawPath(path, paint);

    // Inner dot
    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()..color = MemoryColors.purple.withOpacity(0.5),
    );

    // Corner dots
    final dotPaint = Paint()
      ..color = MemoryColors.cardBackEdge.withOpacity(0.3);
    for (final offset in [
      Offset(cx - r * 0.5, cy - r * 0.5),
      Offset(cx + r * 0.5, cy - r * 0.5),
      Offset(cx - r * 0.5, cy + r * 0.5),
      Offset(cx + r * 0.5, cy + r * 0.5),
    ]) {
      canvas.drawCircle(offset, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────
//  PROGRESS BAR
// ─────────────────────────────────────────────
class MemoryProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const MemoryProgressBar({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: MemoryColors.cardBack,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TIMER DISPLAY
// ─────────────────────────────────────────────
class MemoryTimer extends StatelessWidget {
  final double timeLeft;
  final double total;

  const MemoryTimer({
    super.key,
    required this.timeLeft,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (timeLeft / total).clamp(0.0, 1.0);
    final isLow    = timeLeft < 10;
    final color    = isLow
        ? MemoryColors.primary
        : timeLeft < 20
            ? MemoryColors.warn
            : MemoryColors.accent;

    return Row(
      children: [
        SizedBox(
          width: 40, height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: MemoryColors.surface,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text(
                timeLeft.ceil().toString(),
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
