import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_play/app/theme.dart';

/// Game card for lobby grid — shows icon, name, high score, player count
class GameCard extends StatefulWidget {
  final String gameId;
  final String name;
  final String description;
  final IconData icon;
  final Color accentColor;
  final int highScore;
  final int playerCount;
  final bool isWide;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.gameId,
    required this.name,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.highScore = 0,
    this.playerCount = 0,
    this.isWide = false,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor
                      .withAlpha((_glowAnimation.value * 60).toInt()),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WePlayColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.accentColor.withAlpha(40),
              width: 1,
            ),
          ),
          child: widget.isWide ? _buildWideLayout() : _buildCompactLayout(),
        ),
      ),
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + player count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.accentColor.withAlpha(50),
                    widget.accentColor.withAlpha(20),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.accentColor, size: 28),
            ),
            _playerBadge(),
          ],
        ),
        const SizedBox(height: 12),
        // Game name
        Text(
          widget.name,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: WePlayColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.description,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: WePlayColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        // High score
        if (widget.highScore > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.accentColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded,
                    size: 12, color: widget.accentColor),
                const SizedBox(width: 4),
                Text(
                  _formatScore(widget.highScore),
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.accentColor.withAlpha(50),
                widget.accentColor.withAlpha(20),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(widget.icon, color: widget.accentColor, size: 32),
        ),
        const SizedBox(width: 16),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.name,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: WePlayColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.description,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: WePlayColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Right side
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _playerBadge(),
            if (widget.highScore > 0) ...[
              const SizedBox(height: 6),
              Text(
                _formatScore(widget.highScore),
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.accentColor,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _playerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: WePlayColors.secondary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_rounded,
              size: 10, color: WePlayColors.secondary),
          const SizedBox(width: 3),
          Text(
            '${widget.playerCount}',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: WePlayColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}k';
    }
    return score.toString();
  }
}
