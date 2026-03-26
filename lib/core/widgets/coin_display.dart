import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/core/providers/coin_provider.dart';

/// Animated coin counter display — shows coin icon + count with count-up animation
class CoinDisplay extends ConsumerStatefulWidget {
  final bool compact;

  const CoinDisplay({
    super.key,
    this.compact = false,
  });

  @override
  ConsumerState<CoinDisplay> createState() => _CoinDisplayState();
}

class _CoinDisplayState extends ConsumerState<CoinDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _countAnimation = const AlwaysStoppedAnimation(0.0);
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

    ref.listen<int>(coinNotifierProvider, (previous, next) {
      if (previous != null && previous != next) {
        setState(() {
          _countAnimation = Tween<double>(
            begin: previous.toDouble(),
            end: next.toDouble(),
          ).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut));
          _controller.forward(from: 0);
        });
      }
    });

    final currentCoins = ref.watch(coinNotifierProvider);
    if (!_controller.isAnimating) {
      _countAnimation = AlwaysStoppedAnimation(currentCoins.toDouble());
    }

    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 10 : 14,
        vertical: widget.compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: theme.dividerColor),
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
