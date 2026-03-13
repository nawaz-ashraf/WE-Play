import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/core/widgets/we_play_button.dart';

/// Auth screen — placeholder for Firebase Auth
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WePlayColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [WePlayColors.primary, WePlayColors.secondary],
                ).createShader(bounds),
                child: Text(
                  'WE PLAY',
                  style: GoogleFonts.orbitron(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'sign in to save your progress',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: WePlayColors.textSecondary,
                ),
              ),
              const Spacer(flex: 2),
              // Google sign-in button
              WePlayButton(
                label: 'continue with google',
                icon: Icons.g_mobiledata_rounded,
                onPressed: () => context.go('/lobby'),
                width: double.infinity,
              ),
              const SizedBox(height: 16),
              // Anonymous
              WePlayButton(
                label: 'play as guest',
                icon: Icons.person_outline_rounded,
                onPressed: () => context.go('/lobby'),
                width: double.infinity,
                gradientColors: [
                  WePlayColors.surfaceLight,
                  WePlayColors.surface,
                ],
              ),
              const Spacer(),
              Text(
                'by continuing you agree to our terms',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: WePlayColors.textSecondary.withAlpha(120),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
