import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'trex_models.dart';
import 'trex_provider.dart';

class TrexRunGame extends FlameGame {
  TrexRunGame({required this.notifier});

  final TrexRunNotifier notifier;

  late double _screenW;
  late double _screenH;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _screenW = size.x;
    _screenH = size.y;
    notifier.init(_screenW, _screenH);

    add(_TrexBgRenderer(
        notifier: notifier, screenW: _screenW, screenH: _screenH));
    add(_TrexGroundRenderer(notifier: notifier, screenW: _screenW));
    add(_TrexObstacleRenderer(notifier: notifier));
    add(_TrexCoinRenderer(notifier: notifier));
    add(_TrexPlayerRenderer(notifier: notifier, screenW: _screenW));
  }

  void startGame() => notifier.startGame();
  void jump() => notifier.jump();
  void startDuck() => notifier.startDuck();
  void stopDuck() => notifier.stopDuck();

  @override
  void update(double dt) {
    super.update(dt);
    notifier.tick(dt);
  }
}

class _TrexBgRenderer extends Component {
  _TrexBgRenderer({
    required this.notifier,
    required this.screenW,
    required this.screenH,
  });

  final TrexRunNotifier notifier;
  final double screenW;
  final double screenH;

  @override
  void render(Canvas canvas) {
    final state = notifier.snapshot;
    final skyTop =
        state.isNight ? TrexColors.nightSkyTop : TrexColors.daySkyTop;
    final skyBottom =
        state.isNight ? TrexColors.nightSkyBottom : TrexColors.daySkyBottom;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenW, screenH),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyBottom],
        ).createShader(Rect.fromLTWH(0, 0, screenW, screenH)),
    );
  }
}

class _TrexGroundRenderer extends Component {
  _TrexGroundRenderer({required this.notifier, required this.screenW});

  final TrexRunNotifier notifier;
  final double screenW;

  @override
  void render(Canvas canvas) {
    final state = notifier.snapshot;
    if (state.status == TrexRunStatus.idle) return;

    final groundY = notifier.groundY;
    final ground =
        state.isNight ? TrexColors.nightGround : TrexColors.dayGround;
    final accent =
        state.isNight ? TrexColors.nightAccent : TrexColors.dayAccent;

    canvas.drawRect(
      Rect.fromLTWH(0, groundY, screenW, 260),
      Paint()..color = ground,
    );

    final shadowRect = Rect.fromLTWH(0, groundY - 8, screenW, 8);
    canvas.drawRect(
      shadowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withAlpha(80), Colors.transparent],
        ).createShader(shadowRect),
    );

    canvas.drawLine(
      Offset(0, groundY),
      Offset(screenW, groundY),
      Paint()
        ..color = accent.withAlpha(220)
        ..strokeWidth = 2,
    );

    final linePaint = Paint()
      ..color = accent.withAlpha(130)
      ..strokeWidth = 1.5;

    for (double x = -60; x < screenW + 60; x += 40) {
      final dx = x - state.groundOffset;
      canvas.drawLine(
          Offset(dx, groundY + 9), Offset(dx + 16, groundY + 9), linePaint);
    }
  }
}

class _TrexObstacleRenderer extends Component {
  _TrexObstacleRenderer({required this.notifier});

  final TrexRunNotifier notifier;

  @override
  void render(Canvas canvas) {
    final state = notifier.snapshot;
    for (final obstacle in state.obstacles) {
      switch (obstacle.kind) {
        case TrexObstacleKind.cactusSmall:
        case TrexObstacleKind.cactusTall:
        case TrexObstacleKind.cactusDouble:
          _drawCactus(canvas, obstacle);
          break;
        case TrexObstacleKind.birdLow:
        case TrexObstacleKind.birdHigh:
          _drawBird(canvas, obstacle, state.runFrame);
          break;
      }
    }
  }

  void _drawCactus(Canvas canvas, TrexObstacle obstacle) {
    final cactus = Paint()..color = TrexColors.cactus;

    if (obstacle.kind == TrexObstacleKind.cactusDouble) {
      _drawSingleCactus(canvas, obstacle.x, obstacle.y + 4,
          obstacle.width * 0.42, obstacle.height - 4, cactus);
      _drawSingleCactus(canvas, obstacle.x + obstacle.width * 0.48, obstacle.y,
          obstacle.width * 0.42, obstacle.height, cactus);
      return;
    }

    _drawSingleCactus(canvas, obstacle.x, obstacle.y, obstacle.width,
        obstacle.height, cactus);
  }

  void _drawSingleCactus(
      Canvas canvas, double x, double y, double w, double h, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.3, y, w * 0.4, h),
        const Radius.circular(2),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.1, y + h * 0.35, w * 0.2, h * 0.18),
        const Radius.circular(2),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.7, y + h * 0.2, w * 0.2, h * 0.18),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  void _drawBird(Canvas canvas, TrexObstacle obstacle, int frame) {
    final bodyPaint = Paint()..color = TrexColors.bird;
    final centerY = obstacle.y + obstacle.height * 0.5;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(obstacle.x + obstacle.width * 0.5, centerY),
        width: obstacle.width * 0.42,
        height: obstacle.height * 0.36,
      ),
      bodyPaint,
    );

    final wingTop = frame == 0 ? obstacle.y - 4 : obstacle.y + 4;
    final wing = Path()
      ..moveTo(obstacle.x + obstacle.width * 0.18, centerY)
      ..lineTo(obstacle.x + obstacle.width * 0.5, wingTop)
      ..lineTo(obstacle.x + obstacle.width * 0.82, centerY);

    canvas.drawPath(
      wing,
      Paint()
        ..color = TrexColors.bird
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class _TrexCoinRenderer extends Component {
  _TrexCoinRenderer({required this.notifier});

  final TrexRunNotifier notifier;

  @override
  void render(Canvas canvas) {
    final state = notifier.snapshot;
    for (final coin in state.coins) {
      canvas.drawCircle(
        Offset(coin.x, coin.y),
        14,
        Paint()..color = TrexColors.coin.withAlpha(70),
      );
      canvas.drawCircle(
        Offset(coin.x, coin.y),
        10,
        Paint()..color = TrexColors.coin,
      );
    }
  }
}

class _TrexPlayerRenderer extends Component {
  _TrexPlayerRenderer({required this.notifier, required this.screenW});

  final TrexRunNotifier notifier;
  final double screenW;

  @override
  void render(Canvas canvas) {
    final state = notifier.snapshot;
    if (state.status == TrexRunStatus.idle) return;

    final x = screenW * TrexConst.trexX;
    final y = state.trexY;
    final duckBlend = state.duckBlend;
    final h =
        TrexConst.trexH + (TrexConst.trexDuckH - TrexConst.trexH) * duckBlend;
    final bodyPaint = Paint()..color = TrexColors.trex;

    final centerX = x + TrexConst.trexW / 2;
    final centerY = y + h / 2;
    final jumpScale = state.isOnGround ? 1.0 : 1.04;
    final duckScale = 1 - (duckBlend * 0.3);

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.scale(-1, jumpScale * duckScale);
    canvas.translate(-centerX, -centerY);

    if (state.isDucking) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 7, y + 8, TrexConst.trexW - 3, h - 8),
          const Radius.circular(6),
        ),
        bodyPaint,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 8, y + 12, TrexConst.trexW - 8, h - 12),
          const Radius.circular(6),
        ),
        bodyPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 20, 18),
          const Radius.circular(4),
        ),
        bodyPaint,
      );

      final legShift = state.runFrame == 0 ? 0.0 : 3.5;
      canvas.drawRect(
          Rect.fromLTWH(x + 16, y + h - 8, 6, 8 + legShift), bodyPaint);
      canvas.drawRect(
          Rect.fromLTWH(x + 29, y + h - 8, 6, 8 + (3.5 - legShift)), bodyPaint);
    }

    final tail = Path()
      ..moveTo(x + TrexConst.trexW - 2, y + h * 0.6)
      ..lineTo(x + TrexConst.trexW + 12, y + h * 0.45)
      ..lineTo(x + TrexConst.trexW - 2, y + h * 0.34)
      ..close();

    canvas.drawPath(tail, bodyPaint);
    canvas.drawCircle(
        Offset(x + 11, y + 7), 2.2, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(x + 11.5, y + 7), 1.0, Paint()..color = Colors.black);

    canvas.restore();
  }
}
