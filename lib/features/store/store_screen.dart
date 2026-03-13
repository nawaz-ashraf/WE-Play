import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_play/app/theme.dart';

/// Store screen placeholder
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WePlayColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [WePlayColors.amber, WePlayColors.energy],
                    ).createShader(bounds),
                    child: const Icon(Icons.storefront_rounded,
                        size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'store',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: WePlayColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Coming soon
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: WePlayColors.amber.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_rounded,
                          size: 40, color: WePlayColors.amber),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'coming soon',
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: WePlayColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'skins & power-ups dropping soon 🎨',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: WePlayColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
