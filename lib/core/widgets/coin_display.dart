import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_play/app/theme.dart';

/// Animated coin counter display — shows coin icon + count with count-up animation
class CoinDisplay extends StatefulWidget {
  final int coins;
  final bool compact;

  const CoinDisplay({
    super.key,
    required this.coins,
    this.compact = false,
  });

  @override
  State<CoinDisplay> createState() => _CoinDisplayState();
}

class _CoinDisplayState extends State<CoinDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;
  int _previousCoins = 0;

  @override
  void initState() {
    super.initState();
    _previousCoins = widget.coins;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _countAnimation = Tween<double>(
      begin: widget.coins.toDouble(),
      end: widget.coins.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(CoinDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coins != widget.coins) {
      _countAnimation = Tween<double>(
        begin: _previousCoins.toDouble(),
        end: widget.coins.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _previousCoins = widget.coins;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact ? 16.0 : 20.0;
    final fontSize = widget.compact ? 14.0 : 18.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 10 : 14,
        vertical: widget.compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: WePlayColors.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: WePlayColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded,
              color: WePlayColors.amber, size: iconSize),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, _) {
              return Text(
                _countAnimation.value.toInt().toString(),
                style: GoogleFonts.orbitron(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: WePlayColors.amber,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
