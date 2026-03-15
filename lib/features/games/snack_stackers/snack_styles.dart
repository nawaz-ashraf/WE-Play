import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────
class StackColors {
  static const background    = Color(0xFF0A0A12);
  static const surface       = Color(0xFF13131F);
  static const primary       = Color(0xFF00F5A0); // neon green
  static const accent        = Color(0xFFFFD740); // amber
  static const energy        = Color(0xFFFF3E6C); // pink
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9090B0);
  static const gridLine      = Color(0xFF1A1A2E);
  static const platform      = Color(0xFF2A2A4A);
  static const platformEdge  = Color(0xFF7B61FF);
}

// ─────────────────────────────────────────────
//  GAME CONSTANTS
// ─────────────────────────────────────────────
class StackConst {
  static const double sessionSeconds  = 40.0;
  static const double gravity         = 18.0;   // forge2d world gravity (m/s²)
  static const double worldScale      = 40.0;   // pixels per meter

  // Platform
  static const double platformW       = 0.80;   // fraction of screen width
  static const double platformH       = 18.0;   // px
  static const double platformFromBot = 0.14;   // fraction from bottom

  // Dropper
  static const double dropperY        = 0.12;   // fraction from top
  static const double dropperSpeed    = 120.0;  // px/s lateral

  // Win condition
  static const double coinPerUnit     = 0.02;   // coins per px of height
  static const double wobbleThreshold = 15.0;   // deg before wobble warning
}

// ─────────────────────────────────────────────
//  FOOD ITEM CONFIG
// ─────────────────────────────────────────────
class FoodConfig {
  final String emoji;
  final String name;
  final double width;   // px
  final double height;  // px
  final double density;
  final double restitution;
  final double friction;
  final Color  color;
  final Color  border;

  const FoodConfig({
    required this.emoji,
    required this.name,
    required this.width,
    required this.height,
    required this.density,
    required this.restitution,
    required this.friction,
    required this.color,
    required this.border,
  });
}

const List<FoodConfig> kFoodItems = [
  FoodConfig(
    emoji: '🍔', name: 'Burger',
    width: 64, height: 38,
    density: 1.2, restitution: 0.15, friction: 0.8,
    color: Color(0xFF3D1F00), border: Color(0xFFFFB347),
  ),
  FoodConfig(
    emoji: '🍕', name: 'Pizza',
    width: 70, height: 32,
    density: 0.9, restitution: 0.10, friction: 0.7,
    color: Color(0xFF3D0A00), border: Color(0xFFFF6B35),
  ),
  FoodConfig(
    emoji: '🍣', name: 'Sushi',
    width: 58, height: 30,
    density: 1.0, restitution: 0.20, friction: 0.6,
    color: Color(0xFF0A2A3D), border: Color(0xFF4FC3F7),
  ),
  FoodConfig(
    emoji: '🧁', name: 'Cupcake',
    width: 50, height: 52,
    density: 0.7, restitution: 0.25, friction: 0.5,
    color: Color(0xFF2D0040), border: Color(0xFFCE93D8),
  ),
  FoodConfig(
    emoji: '🌮', name: 'Taco',
    width: 66, height: 44,
    density: 1.1, restitution: 0.12, friction: 0.75,
    color: Color(0xFF1A2D00), border: Color(0xFF8BC34A),
  ),
  FoodConfig(
    emoji: '🍩', name: 'Donut',
    width: 56, height: 36,
    density: 0.6, restitution: 0.35, friction: 0.45,
    color: Color(0xFF3D0020), border: Color(0xFFFF4081),
  ),
  FoodConfig(
    emoji: '🥪', name: 'Sandwich',
    width: 68, height: 34,
    density: 1.3, restitution: 0.08, friction: 0.85,
    color: Color(0xFF2D1A00), border: Color(0xFFFFD740),
  ),
];
