import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────
class SnakeColors {
  static const background    = Color(0xFF0A0A12);
  static const surface       = Color(0xFF13131F);
  static const primary       = Color(0xFF00F5A0); // neon green
  static const accent        = Color(0xFF7B61FF); // purple
  static const energy        = Color(0xFFFF3E6C); // pink
  static const warn          = Color(0xFFFFD740); // amber
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9090B0);

  // Grid
  static const gridBg        = Color(0xFF0D0D1A);
  static const gridLine      = Color(0xFF111120);
  static const cellEmpty     = Color(0xFF0D0D1A);

  // Snake
  static const snakeHead     = Color(0xFF00F5A0);
  static const snakeHeadGlow = Color(0x5500F5A0);
  static const snakeBody     = Color(0xFF00C880);
  static const snakeTail     = Color(0xFF008855);
  static const snakeBorder   = Color(0xFF00F5A0);

  // Food types
  static const foodApple     = Color(0xFFFF3E6C);
  static const foodStar      = Color(0xFFFFD740);
  static const foodGem       = Color(0xFF7B61FF);
  static const foodBomb      = Color(0xFFFF6B35);
}

// ─────────────────────────────────────────────
//  GAME CONSTANTS
// ─────────────────────────────────────────────
class SnakeConst {
  static const int   cols          = 20;
  static const int   rows          = 26;
  static const double cellSize     = 18.0; // px

  // Speed in cells/second (increases with score)
  static const double speedBase    = 6.0;
  static const double speedInc     = 0.3;  // per food eaten
  static const double speedMax     = 18.0;

  // Scoring
  static const int   scoreApple    = 10;
  static const int   scoreStar     = 25;  // rare spawn
  static const int   scoreGem      = 50;  // very rare spawn
  static const int   coinEvery     = 30;  // score points per coin

  // Special food spawn chance (out of 100)
  static const int   starChance    = 20;
  static const int   gemChance     = 8;

  // Special food lifespan (seconds)
  static const double starLifespan = 6.0;
  static const double gemLifespan  = 4.0;
}

// ─────────────────────────────────────────────
//  DIRECTION
// ─────────────────────────────────────────────
enum SnakeDirection { up, down, left, right }

extension SnakeDirectionX on SnakeDirection {
  bool isOpposite(SnakeDirection other) {
    if (this == SnakeDirection.up    && other == SnakeDirection.down)  return true;
    if (this == SnakeDirection.down  && other == SnakeDirection.up)    return true;
    if (this == SnakeDirection.left  && other == SnakeDirection.right) return true;
    if (this == SnakeDirection.right && other == SnakeDirection.left)  return true;
    return false;
  }

  Point get delta {
    switch (this) {
      case SnakeDirection.up:    return const Point(0, -1);
      case SnakeDirection.down:  return const Point(0,  1);
      case SnakeDirection.left:  return const Point(-1, 0);
      case SnakeDirection.right: return const Point( 1, 0);
    }
  }
}

// ─────────────────────────────────────────────
//  POINT  (grid coordinate)
// ─────────────────────────────────────────────
class Point {
  final int x, y;
  const Point(this.x, this.y);

  Point operator +(Point other) => Point(x + other.x, y + other.y);

  @override
  bool operator ==(Object o) => o is Point && o.x == x && o.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

// ─────────────────────────────────────────────
//  FOOD TYPE
// ─────────────────────────────────────────────
enum FoodType { apple, star, gem }

extension FoodTypeX on FoodType {
  String get emoji {
    switch (this) {
      case FoodType.apple: return '🍎';
      case FoodType.star:  return '⭐';
      case FoodType.gem:   return '💎';
    }
  }

  int get score {
    switch (this) {
      case FoodType.apple: return SnakeConst.scoreApple;
      case FoodType.star:  return SnakeConst.scoreStar;
      case FoodType.gem:   return SnakeConst.scoreGem;
    }
  }

  Color get color {
    switch (this) {
      case FoodType.apple: return SnakeColors.foodApple;
      case FoodType.star:  return SnakeColors.foodStar;
      case FoodType.gem:   return SnakeColors.foodGem;
    }
  }
}

// ─────────────────────────────────────────────
//  FOOD ITEM
// ─────────────────────────────────────────────
class FoodItem {
  final Point    position;
  final FoodType type;
  double         lifespan; // seconds remaining (-1 = permanent)

  FoodItem({
    required this.position,
    required this.type,
    required this.lifespan,
  });

  bool get isExpiring => lifespan > 0 && lifespan < 2.0;
  bool get isExpired  => lifespan == 0;
}
