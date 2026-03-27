import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COLOR SWITCH TAP – DESIGN TOKENS
// ─────────────────────────────────────────────

class CSColors {
  // App chrome
  static const background    = Color(0xFF0A0A12);
  static const surface       = Color(0xFF13131F);
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9090B0);
  static const overlay       = Color(0xCC0A0A12); // 80% opacity bg

  // The 4 game colours
  static const red    = Color(0xFFFF3E6C);
  static const blue   = Color(0xFF4FC3F7);
  static const green  = Color(0xFF00F5A0);
  static const yellow = Color(0xFFFFD740);

  static const List<Color> gameColors = [red, blue, green, yellow];

  // UI accents
  static const accent  = Color(0xFF7B61FF);
  static const coin    = Color(0xFFFFD740);
}

class CSConst {
  // Physics
  static const double gravity       = 800.0;
  static const double jumpVelocity  = -400.0;
  static const double ballRadius    = 16.0;

  // Obstacles
  static const double obstacleRadius      = 145.0;
  static const double obstacleThickness   = 32.0;
  static const double obstacleGap         = 580.0; // vertical spacing
  static const double scrollSpeed         = 80.0;
  static const double speedIncrement      = 2.0;   // per obstacle passed
  static const double obstacleRotationSpeed = 1.5; // radians per second

  // Colour switcher
  static const double switcherRadius      = 14.0;

  // Scoring / coins
  static const int    coinsPerScore       = 5; // 1 coin per N points
}
