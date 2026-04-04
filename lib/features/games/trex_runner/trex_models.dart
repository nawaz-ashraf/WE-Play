import 'package:flutter/material.dart';

enum TrexRunStatus { idle, playing, dead }

enum TrexObstacleKind {
  cactusSmall,
  cactusTall,
  cactusDouble,
  birdLow,
  birdHigh
}

class TrexColors {
  static const background = Color(0xFF090912);

  static const daySky = Color(0xFF0D1025);
  static const daySkyTop = Color(0xFF0B0F24);
  static const daySkyBottom = Color(0xFF151C3C);
  static const dayGround = Color(0xFF1A1F42);
  static const dayAccent = Color(0xFF00E5A8);

  static const nightSky = Color(0xFF1A1408);
  static const nightSkyTop = Color(0xFF1A1306);
  static const nightSkyBottom = Color(0xFF2E2412);
  static const nightGround = Color(0xFF2E2615);
  static const nightAccent = Color(0xFFFFD740);

  static const text = Color(0xFFF2F2FF);
  static const subtle = Color(0xFF9FA2C8);

  static const cactus = Color(0xFF00D084);
  static const bird = Color(0xFFFF6A88);
  static const trex = Color(0xFFBFC4FF);
  static const coin = Color(0xFFFFD740);
}

class TrexConst {
  static const trexX = 0.18;
  static const trexW = 44.0;
  static const trexH = 50.0;
  static const trexDuckH = 30.0;

  static const groundFactor = 0.82;

  static const jumpVelocity = -880.0;
  static const gravity = 1920.0;

  static const speedBase = 260.0;
  static const speedInc = 7.0;
  static const speedMax = 590.0;

  static const spawnBase = 1.42;
  static const spawnMin = 0.56;

  static const scoreStep = 10.0;
}

class TrexObstacle {
  const TrexObstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.kind,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final TrexObstacleKind kind;

  TrexObstacle copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    TrexObstacleKind? kind,
  }) {
    return TrexObstacle(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      kind: kind ?? this.kind,
    );
  }

  Rect get hitRect => Rect.fromLTWH(
        x + width * 0.15,
        y + height * 0.12,
        width * 0.72,
        height * 0.76,
      );
}

class TrexCoin {
  const TrexCoin({required this.x, required this.y});

  final double x;
  final double y;

  TrexCoin copyWith({double? x, double? y}) {
    return TrexCoin(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Rect get hitRect => Rect.fromCircle(center: Offset(x, y), radius: 10);
}
