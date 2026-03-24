import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────
class FlappyColors {
  static const background     = Color(0xFF0A0A12);
  static const surface        = Color(0xFF13131F);
  static const primary        = Color(0xFF7B61FF);
  static const accent         = Color(0xFF00F5A0);
  static const energy         = Color(0xFFFF3E6C);
  static const warn           = Color(0xFFFFD740);
  static const textPrimary    = Color(0xFFF2F2FF);
  static const textSecondary  = Color(0xFF9090B0);

  // Sky gradient stops
  static const skyTop         = Color(0xFF0D0D2E);
  static const skyBottom      = Color(0xFF1A0A2E);

  // Bird
  static const birdBody       = Color(0xFF7B61FF);
  static const birdWing       = Color(0xFF5A45CC);
  static const birdEye        = Color(0xFFF2F2FF);
  static const birdBeak       = Color(0xFFFFD740);
  static const birdGlow       = Color(0x557B61FF);

  // Pipes
  static const pipeBody       = Color(0xFF1A3A1A);
  static const pipeEdge       = Color(0xFF00F5A0);
  static const pipeCap        = Color(0xFF0F2A0F);
  static const pipeGlow       = Color(0x2200F5A0);

  // Ground
  static const groundTop      = Color(0xFF1A1A0A);
  static const groundLine     = Color(0xFF2A2A1A);

  // Stars
  static const star           = Color(0xFFFFFFFF);
}

// ─────────────────────────────────────────────
//  GAME CONSTANTS
// ─────────────────────────────────────────────
class FlappyConst {
  // Bird
  static const double birdX           = 0.25;   // fraction of screen width
  static const double birdRadius      = 16.0;   // px
  static const double flapImpulse     = -520.0; // px/s upward velocity on tap
  static const double gravity         = 1100.0; // px/s²

  // Pipes
  static const double pipeWidth       = 64.0;
  static const double pipeGap         = 180.0;  // gap between top/bottom pipe
  static const double pipeSpacing     = 260.0;  // horizontal distance between pipes
  static const double pipeSpeedBase   = 180.0;  // px/s
  static const double pipeSpeedInc    = 4.0;    // px/s added per scored pipe
  static const double pipeSpeedMax    = 380.0;

  // Ground
  static const double groundH         = 60.0;   // px

  // Scoring
  static const int    coinEvery       = 5;      // coins per 5 pipes scored

  // Difficulty
  static const double gapShrinkEvery  = 10;     // pipes before gap shrinks
  static const double gapMin          = 130.0;
}

// ─────────────────────────────────────────────
//  STAR DATA  (static background decoration)
// ─────────────────────────────────────────────
class StarData {
  final double x, y, radius, opacity;
  const StarData({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
  });
}
