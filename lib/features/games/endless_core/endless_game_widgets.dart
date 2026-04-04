import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EndlessHudPill extends StatelessWidget {
  const EndlessHudPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(130)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class GameControlButton extends StatefulWidget {
  const GameControlButton({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 62,
    this.onPressed,
    this.onHoldStart,
    this.onHoldEnd,
    this.semanticsLabel,
  });

  final IconData icon;
  final Color accent;
  final double size;
  final VoidCallback? onPressed;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;
  final String? semanticsLabel;

  @override
  State<GameControlButton> createState() => _GameControlButtonState();
}

class _GameControlButtonState extends State<GameControlButton> {
  bool _pressed = false;

  bool get _isHold => widget.onHoldStart != null || widget.onHoldEnd != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final scale = _pressed ? 0.96 : 1.0;
    final opacity = _pressed ? 0.85 : 1.0;

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isHold ? null : widget.onPressed,
        onTapDown: (_) {
          _setPressed(true);
          widget.onHoldStart?.call();
        },
        onTapUp: (_) {
          _setPressed(false);
          widget.onHoldEnd?.call();
        },
        onTapCancel: () {
          _setPressed(false);
          widget.onHoldEnd?.call();
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 90),
          child: AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 90),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withAlpha(120),
                    Colors.black.withAlpha(160),
                  ],
                ),
                border: Border.all(color: accent.withAlpha(170)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
