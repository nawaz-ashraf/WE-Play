import 'package:flutter/material.dart';

enum HotAirBalloonStatus { idle, playing, dead }

enum HabObstacleType { bird, cloud, pole, drone, kite }

class HabColors {
  static const background = Color(0xFF090916);
  static const skyTop = Color(0xFF070A1F);
  static const skyMid = Color(0xFF0F1535);
  static const skyBottom = Color(0xFF141C45);
  static const star = Color(0xFFFFFFFF);

  static const balloonRed = Color(0xFFFF5B7F);
  static const balloonYellow = Color(0xFFFFD740);
  static const balloonPurple = Color(0xFF7B61FF);
  static const basket = Color(0xFF8B4513);
  static const rope = Color(0xFFD2691E);
  static const flame = Color(0xFFFF9E42);

  static const hudText = Color(0xFFF5F5FF);
  static const hudSubtle = Color(0xFF9B9BC6);
  static const coin = Color(0xFFFFD740);

  static const bird = Color(0xFF9DA0C9);
  static const cloud = Color(0xFF2E3266);
  static const pole = Color(0xFF5E5B8A);
  static const drone = Color(0xFF7BC4FF);
  static const kite = Color(0xFFFF8A65);
}

class HabConst {
  static const balloonW = 60.0;
  static const balloonH = 82.0;
  static const balloonStartX = 0.28;
  static const horizontalAccel = 900.0;
  static const horizontalMaxSpeed = 260.0;
  static const horizontalDamping = 6.5;

  static const gravity = 280.0;
  static const burnLift = -430.0;
  static const maxVelocity = 320.0;
  static const tapImpulse = -120.0;

  static const worldSpeedBase = 150.0;
  static const worldSpeedInc = 2.5;
  static const worldSpeedMax = 390.0;

  static const safeTop = 66.0;
  static const safeBottom = 86.0;
  static const safeSide = 14.0;

  static const spawnIntervalBase = 1.45;
  static const spawnIntervalMin = 0.62;
}

class HabObstacle {
  const HabObstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    required this.horizontalVelocity,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final HabObstacleType type;
  final double horizontalVelocity;

  HabObstacle copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    HabObstacleType? type,
    double? horizontalVelocity,
  }) {
    return HabObstacle(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      type: type ?? this.type,
      horizontalVelocity: horizontalVelocity ?? this.horizontalVelocity,
    );
  }

  Rect get hitRect => Rect.fromLTWH(
        x + width * 0.15,
        y + height * 0.15,
        width * 0.7,
        height * 0.7,
      );
}

class HabCoin {
  const HabCoin({
    required this.x,
    required this.y,
    this.collected = false,
    this.pulse = 0,
  });

  final double x;
  final double y;
  final bool collected;
  final double pulse;

  HabCoin copyWith({
    double? x,
    double? y,
    bool? collected,
    double? pulse,
  }) {
    return HabCoin(
      x: x ?? this.x,
      y: y ?? this.y,
      collected: collected ?? this.collected,
      pulse: pulse ?? this.pulse,
    );
  }

  Rect get hitRect => Rect.fromCircle(center: Offset(x, y), radius: 11);
}
