import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:we_play/app/theme.dart';

/// Pill-shaped gradient button with haptic feedback — WE PLAY primary CTA
class WePlayButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final List<Color>? gradientColors;
  final double? width;
  final bool isSmall;

  const WePlayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradientColors,
    this.width,
    this.isSmall = false,
  });

  @override
  State<WePlayButton> createState() => _WePlayButtonState();
}

class _WePlayButtonState extends State<WePlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ??
        [WePlayColors.primary, WePlayColors.primary.withAlpha(200)];
    final verticalPad = widget.isSmall ? 10.0 : 16.0;
    final horizontalPad = widget.isSmall ? 20.0 : 32.0;
    final fontSize = widget.isSmall ? 13.0 : 16.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          width: widget.width,
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPad, vertical: verticalPad),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: colors.first.withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: fontSize + 4),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
