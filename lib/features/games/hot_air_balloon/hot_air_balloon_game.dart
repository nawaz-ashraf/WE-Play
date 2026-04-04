import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'hot_air_balloon_models.dart';
import 'hot_air_balloon_provider.dart';

class HotAirBalloonGame extends FlameGame {
  HotAirBalloonGame({required this.notifier});

  final HotAirBalloonNotifier notifier;

  late double _screenW;
  late double _screenH;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _screenW = size.x;
    _screenH = size.y;
    notifier.init(_screenW, _screenH);

    add(_HabSkyRenderer(
        notifier: notifier, screenW: _screenW, screenH: _screenH));
    add(_HabObjectsRenderer(notifier: notifier));
    add(_HabBalloonRenderer(notifier: notifier, screenW: _screenW));
    add(_HabBoundsRenderer(screenW: _screenW, screenH: _screenH));
  }

  void startGame() => notifier.startGame();
  void setBurning(bool isBurning) => notifier.setBurning(isBurning);
  void setHorizontalInput(double input) => notifier.setHorizontalInput(input);

  @override
  void update(double dt) {
    super.update(dt);
    notifier.tick(dt);
  }
}

class _HabSkyRenderer extends Component {
  _HabSkyRenderer({
    required this.notifier,
    required this.screenW,
    required this.screenH,
  });

  final HotAirBalloonNotifier notifier;
  final double screenW;
  final double screenH;

  final _rng = Random();
  final List<_SkyStar> _stars = [];

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < 44; i++) {
      _stars.add(
        _SkyStar(
          x: _rng.nextDouble() * screenW,
          y: _rng.nextDouble() * screenH,
          r: 0.7 + _rng.nextDouble() * 1.3,
          speedFactor: 0.4 + _rng.nextDouble() * 1.2,
          alpha: 80 + _rng.nextInt(110),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    final speed = notifier.snapshot.worldSpeed;
    for (final s in _stars) {
      s.y += (20 + speed * 0.35) * s.speedFactor * dt;
      if (s.y > screenH + 3) {
        s.y = -3;
        s.x = _rng.nextDouble() * screenW;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, screenW, screenH);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HabColors.skyTop, HabColors.skyMid, HabColors.skyBottom],
        ).createShader(rect),
    );

    for (final s in _stars) {
      canvas.drawCircle(
        Offset(s.x, s.y),
        s.r,
        Paint()..color = HabColors.star.withAlpha(s.alpha),
      );
    }
  }
}

class _HabObjectsRenderer extends Component {
  _HabObjectsRenderer({required this.notifier});

  final HotAirBalloonNotifier notifier;

  @override
  void render(Canvas canvas) {
    final state = notifier.snapshot;

    for (final obstacle in state.obstacles) {
      switch (obstacle.type) {
        case HabObstacleType.bird:
          _drawBird(canvas, obstacle);
          break;
        case HabObstacleType.cloud:
          _drawCloud(canvas, obstacle);
          break;
        case HabObstacleType.pole:
          _drawPole(canvas, obstacle);
          break;
        case HabObstacleType.drone:
          _drawDrone(canvas, obstacle);
          break;
        case HabObstacleType.kite:
          _drawKite(canvas, obstacle);
          break;
      }
    }

    for (final coin in state.coins) {
      final radius = 10.5 + sin(coin.pulse) * 1.2;
      canvas.drawCircle(
        Offset(coin.x, coin.y),
        radius + 4,
        Paint()..color = HabColors.coin.withAlpha(65),
      );
      canvas.drawCircle(
        Offset(coin.x, coin.y),
        radius,
        Paint()..color = HabColors.coin,
      );
      canvas.drawCircle(
        Offset(coin.x - 3, coin.y - 3),
        2.2,
        Paint()..color = Colors.white.withAlpha(170),
      );
    }
  }

  void _drawBird(Canvas canvas, HabObstacle obstacle) {
    final wing = Path()
      ..moveTo(obstacle.x, obstacle.y + obstacle.height * 0.6)
      ..lineTo(obstacle.x + obstacle.width * 0.38,
          obstacle.y + obstacle.height * 0.24)
      ..lineTo(obstacle.x + obstacle.width * 0.5,
          obstacle.y + obstacle.height * 0.52)
      ..lineTo(obstacle.x + obstacle.width * 0.62,
          obstacle.y + obstacle.height * 0.24)
      ..lineTo(obstacle.x + obstacle.width, obstacle.y + obstacle.height * 0.6);

    canvas.drawPath(
      wing,
      Paint()
        ..color = HabColors.bird
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawCloud(Canvas canvas, HabObstacle obstacle) {
    final p = Paint()..color = HabColors.cloud.withAlpha(210);
    canvas.drawCircle(
      Offset(obstacle.x + obstacle.width * 0.24,
          obstacle.y + obstacle.height * 0.62),
      obstacle.height * 0.25,
      p,
    );
    canvas.drawCircle(
      Offset(obstacle.x + obstacle.width * 0.5,
          obstacle.y + obstacle.height * 0.48),
      obstacle.height * 0.34,
      p,
    );
    canvas.drawCircle(
      Offset(obstacle.x + obstacle.width * 0.76,
          obstacle.y + obstacle.height * 0.62),
      obstacle.height * 0.25,
      p,
    );
  }

  void _drawPole(Canvas canvas, HabObstacle obstacle) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(obstacle.x, obstacle.y, obstacle.width, obstacle.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = HabColors.pole);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.white.withAlpha(45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawDrone(Canvas canvas, HabObstacle obstacle) {
    final center = Offset(
      obstacle.x + obstacle.width / 2,
      obstacle.y + obstacle.height / 2,
    );
    final bodyPaint = Paint()..color = HabColors.drone;

    canvas.drawCircle(center, obstacle.height * 0.22, bodyPaint);
    canvas.drawLine(
      Offset(center.dx - obstacle.width * 0.35, center.dy),
      Offset(center.dx + obstacle.width * 0.35, center.dy),
      Paint()
        ..color = HabColors.drone.withAlpha(210)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(center.dx - obstacle.width * 0.34, center.dy),
      4,
      Paint()..color = Colors.white.withAlpha(140),
    );
    canvas.drawCircle(
      Offset(center.dx + obstacle.width * 0.34, center.dy),
      4,
      Paint()..color = Colors.white.withAlpha(140),
    );
  }

  void _drawKite(Canvas canvas, HabObstacle obstacle) {
    final kitePath = Path()
      ..moveTo(obstacle.x + obstacle.width / 2, obstacle.y)
      ..lineTo(obstacle.x + obstacle.width, obstacle.y + obstacle.height / 2)
      ..lineTo(obstacle.x + obstacle.width / 2, obstacle.y + obstacle.height)
      ..lineTo(obstacle.x, obstacle.y + obstacle.height / 2)
      ..close();

    canvas.drawPath(kitePath, Paint()..color = HabColors.kite);
    canvas.drawPath(
      kitePath,
      Paint()
        ..color = Colors.white.withAlpha(65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }
}

class _HabBalloonRenderer extends Component {
  _HabBalloonRenderer({required this.notifier, required this.screenW});

  final HotAirBalloonNotifier notifier;
  final double screenW;
  double _time = 0;

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final state = notifier.snapshot;
    if (state.status == HotAirBalloonStatus.idle) return;

    final x = state.balloonX;
    final y = state.balloonY;

    final envelope =
        Rect.fromLTWH(x, y, HabConst.balloonW, HabConst.balloonH * 0.72);
    final clip = Path()..addOval(envelope);

    if (state.isBurning) {
      canvas.drawOval(
        Rect.fromCenter(
          center:
              Offset(x + HabConst.balloonW * 0.5, y + HabConst.balloonH * 0.36),
          width: HabConst.balloonW * 1.3,
          height: HabConst.balloonH * 0.95,
        ),
        Paint()..color = HabColors.flame.withAlpha(45),
      );
    }

    canvas.save();
    canvas.clipPath(clip);

    final stripeW = envelope.width / 3;
    canvas.drawRect(
      Rect.fromLTWH(envelope.left, envelope.top, stripeW, envelope.height),
      Paint()..color = HabColors.balloonRed,
    );
    canvas.drawRect(
      Rect.fromLTWH(
          envelope.left + stripeW, envelope.top, stripeW, envelope.height),
      Paint()..color = HabColors.balloonYellow,
    );
    canvas.drawRect(
      Rect.fromLTWH(
          envelope.left + stripeW * 2, envelope.top, stripeW, envelope.height),
      Paint()..color = HabColors.balloonPurple,
    );

    canvas.restore();
    canvas.drawOval(
      envelope,
      Paint()
        ..color = Colors.white.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final basketLeft = x + HabConst.balloonW * 0.34;
    final basketTop = y + HabConst.balloonH * 0.75;
    final basketRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(basketLeft, basketTop, 20, 16),
      const Radius.circular(3),
    );
    canvas.drawRRect(basketRect, Paint()..color = HabColors.basket);

    final rope = Paint()
      ..color = HabColors.rope
      ..strokeWidth = 1.3;
    final ropeTop = y + HabConst.balloonH * 0.62;
    canvas.drawLine(
        Offset(x + 13, ropeTop), Offset(basketLeft, basketTop), rope);
    canvas.drawLine(
        Offset(x + 22, ropeTop), Offset(basketLeft + 4, basketTop), rope);
    canvas.drawLine(
        Offset(x + 38, ropeTop), Offset(basketLeft + 16, basketTop), rope);
    canvas.drawLine(
        Offset(x + 47, ropeTop), Offset(basketLeft + 20, basketTop), rope);

    if (state.isBurning) {
      final flameHeight = 9 + sin(_time * 18) * 2;
      final flame = Path()
        ..moveTo(x + HabConst.balloonW * 0.5, basketTop + 1)
        ..quadraticBezierTo(
          x + HabConst.balloonW * 0.44,
          basketTop - flameHeight,
          x + HabConst.balloonW * 0.5,
          basketTop - flameHeight * 1.2,
        )
        ..quadraticBezierTo(
          x + HabConst.balloonW * 0.56,
          basketTop - flameHeight,
          x + HabConst.balloonW * 0.5,
          basketTop + 1,
        );
      canvas.drawPath(flame, Paint()..color = HabColors.flame);
    }
  }
}

class _HabBoundsRenderer extends Component {
  _HabBoundsRenderer({required this.screenW, required this.screenH});

  final double screenW;
  final double screenH;

  @override
  void render(Canvas canvas) {
    final bottomY = screenH - HabConst.safeBottom;
    final line = Paint()
      ..color = Colors.white.withAlpha(28)
      ..strokeWidth = 1;

    canvas.drawLine(
      const Offset(0, HabConst.safeTop),
      Offset(screenW, HabConst.safeTop),
      line,
    );
    canvas.drawLine(
      Offset(0, bottomY),
      Offset(screenW, bottomY),
      line,
    );
  }
}

class _SkyStar {
  _SkyStar({
    required this.x,
    required this.y,
    required this.r,
    required this.speedFactor,
    required this.alpha,
  });

  double x;
  double y;
  final double r;
  final double speedFactor;
  final int alpha;
}
