import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/core/widgets/coin_display.dart';

/// Profile screen placeholder
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WePlayColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'profile',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: WePlayColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_rounded,
                        color: WePlayColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [WePlayColors.primary, WePlayColors.energy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: WePlayColors.primary.withAlpha(80),
                    width: 3,
                  ),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Player_1',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: WePlayColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'level 12 • 4,800 xp',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: WePlayColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const CoinDisplay(coins: 1250),
              const SizedBox(height: 32),
              // Stats grid
              Row(
                children: [
                  _StatCard(
                    label: 'games played',
                    value: '127',
                    icon: Icons.videogame_asset_rounded,
                    color: WePlayColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'win streak',
                    value: '5 🔥',
                    icon: Icons.local_fire_department_rounded,
                    color: WePlayColors.energy,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    label: 'best combo',
                    value: '48x',
                    icon: Icons.bolt_rounded,
                    color: WePlayColors.amber,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'login streak',
                    value: '5 days',
                    icon: Icons.calendar_today_rounded,
                    color: WePlayColors.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WePlayColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: WePlayColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: WePlayColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
