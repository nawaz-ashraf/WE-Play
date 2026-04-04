import 'package:flutter/material.dart';

enum DoodleStatus { idle, playing, dead }

enum DoodlePlatformType { normal, moving, breaking, spring }

class DoodleColors {
  static const background = Color(0xFF090916);
  static const surface = Color(0xFF13132A);
  static const primary = Color(0xFF4FC3F7);
  static const accent = Color(0xFF7B61FF);
  static const warning = Color(0xFFFFD740);
  static const text = Color(0xFFF2F2FF);
  static const subtle = Color(0xFF9DA2CB);

  static const doodlerBody = Color(0xFF7B61FF);
  static const doodlerFeet = Color(0xFFFFD740);
  static const doodlerEye = Color(0xFFF2F2FF);

  static const platformNormal = Color(0xFF8B7CFF);
  static const platformMoving = Color(0xFF4FC3F7);
  static const platformBreaking = Color(0xFFFF8A65);
  static const platformSpring = Color(0xFFFFD740);
}

class DoodleConst {
  static const doodlerW = 40.0;
  static const doodlerH = 40.0;
  static const gravity = 1400.0;
  static const bounceVelocity = -900.0;
  static const springVelocity = -1450.0;
  static const moveSpeed = 250.0;

  static const platformW = 74.0;
  static const platformH = 14.0;
  static const platformGap = 112.0;

  static const scrollThresholdFactor = 0.42;
  static const scoreStep = 10.0;
}

class DoodlePlatform {
  const DoodlePlatform({
    required this.x,
    required this.y,
    required this.type,
    this.moveDir = 1,
    this.broken = false,
    this.breakAnim = 0,
  });

  final double x;
  final double y;
  final DoodlePlatformType type;
  final double moveDir;
  final bool broken;
  final double breakAnim;

  DoodlePlatform copyWith({
    double? x,
    double? y,
    DoodlePlatformType? type,
    double? moveDir,
    bool? broken,
    double? breakAnim,
  }) {
    return DoodlePlatform(
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      moveDir: moveDir ?? this.moveDir,
      broken: broken ?? this.broken,
      breakAnim: breakAnim ?? this.breakAnim,
    );
  }

  Color get color {
    switch (type) {
      case DoodlePlatformType.normal:
        return DoodleColors.platformNormal;
      case DoodlePlatformType.moving:
        return DoodleColors.platformMoving;
      case DoodlePlatformType.breaking:
        return DoodleColors.platformBreaking;
      case DoodlePlatformType.spring:
        return DoodleColors.platformSpring;
    }
  }
}

class DoodleCoin {
  const DoodleCoin({
    required this.x,
    required this.y,
    this.pulse = 0,
  });

  final double x;
  final double y;
  final double pulse;

  DoodleCoin copyWith({double? x, double? y, double? pulse}) {
    return DoodleCoin(
      x: x ?? this.x,
      y: y ?? this.y,
      pulse: pulse ?? this.pulse,
    );
  }

  Rect get hitRect => Rect.fromCircle(center: Offset(x, y), radius: 10);
}
