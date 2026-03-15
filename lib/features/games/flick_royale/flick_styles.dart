import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────
class FlickColors {
  static const background    = Color(0xFF0A0A12);
  static const surface       = Color(0xFF13131F);
  static const primary       = Color(0xFF7B61FF);
  static const accent        = Color(0xFF00F5A0);
  static const energy        = Color(0xFFFF3E6C);
  static const warn          = Color(0xFFFFD740);
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9090B0);

  // Arena
  static const arenaFloor    = Color(0xFF0D0D1F);
  static const arenaBorder   = Color(0xFF2A2A50);
  static const centreLine    = Color(0xFF1E1E3A);
  static const playerZone    = Color(0xFF0D1A2A);
  static const aiZone        = Color(0xFF1A0D1A);

  // Puck colours
  static const playerPuck    = Color(0xFF7B61FF); // purple
  static const aiPuck        = Color(0xFFFF3E6C); // pink
  static const puckGlow      = Color(0x557B61FF);
}

// ─────────────────────────────────────────────
//  GAME CONSTANTS
// ─────────────────────────────────────────────
class FlickConst {
  static const int    pucksPerSide   = 3;
  static const int    rounds         = 3;
  static const double roundSeconds   = 20.0;
  static const double worldScale     = 40.0;   // px per metre

  // Physics
  static const double puckRadius     = 18.0;   // px
  static const double puckMass       = 1.0;
  static const double puckRestitution= 0.82;
  static const double puckFriction   = 0.08;
  static const double linearDamping  = 0.55;   // rolling friction
  static const double maxFlickImpulse= 14.0;   // m/s cap

  // Arena (fraction of screen)
  static const double arenaMargin    = 0.04;
  static const double centreFrac     = 0.50;   // centre line Y fraction

  // Scoring
  static const int    coinsPerRoundWin = 3;
  static const int    coinsPerMatchWin = 10;

  // AI difficulty tiers
  static const List<double> aiAccuracy   = [0.55, 0.65, 0.75, 0.85, 0.95];
  static const List<double> aiSpeedMult  = [0.60, 0.70, 0.80, 0.90, 1.00];
  static const List<double> aiDelayRange = [1.20, 0.95, 0.75, 0.55, 0.35];
}

// ─────────────────────────────────────────────
//  PUCK OWNER
// ─────────────────────────────────────────────
enum PuckOwner { player, ai }

// ─────────────────────────────────────────────
//  ROUND RESULT
// ─────────────────────────────────────────────
enum RoundWinner { player, ai, draw }
