import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'doodle_models.dart';
import 'doodle_provider.dart';

class DoodleGame extends FlameGame {
  DoodleGame({required this.notifier});

  final DoodleNotifier notifier;

  late double _screenW;
  late double _screenH;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _screenW = size.x;
    _screenH = size.y;
    notifier.init(_screenW, _screenH);

    add(_DoodleBackground(screenW: _screenW, screenH: _screenH));
    add(_DoodlePlatformRenderer(notifier: notifier));
    add(_DoodleCoinRenderer(notifier: notifier));
    add(_DoodlerRenderer(notifier: notifier));
  }

  void startGame() => notifier.startGame();
  void moveLeft() => notifier.setHorizontalInput(-1);
  void moveRight() => notifier.setHorizontalInput(1);
  void stopMove() => notifier.setHorizontalInput(0);

  @override
  void update(double dt) {
    super.update(dt);
    notifier.tick(dt);
  }
}

class _DoodleBackground extends Component {
  _DoodleBackground({required this.screenW, required this.screenH});

  final double screenW;
  final double screenH;

  final _rng = Random();
  final _stars = <_Star>[];

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < 48; i++) {
      _stars.add(
        _Star(
          x: _rng.nextDouble() * screenW,
          y: _rng.nextDouble() * screenH,
          r: 0.7 + _rng.nextDouble() * 1.4,
          speed: 8 + _rng.nextDouble() * 18,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    for (final star in _stars) {
      star.y += star.speed * dt;
      if (star.y > screenH + 2) {
        star.y = -2;
        star.x = _rng.nextDouble() * screenW;
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
          colors: [
            Color(0xFF060611),
            DoodleColors.background,
            DoodleColors.surface
          ],
        ).createShader(rect),
    );

    for (final star in _stars) {
      canvas.drawCircle(
        Offset(star.x, star.y),
        star.r,
        Paint()..color = Colors.white.withAlpha(130),
      );
    }
  }
}

class _DoodlePlatformRenderer extends Component {
  _DoodlePlatformRenderer({required this.notifier});

  final DoodleNotifier notifier;

  @override
  void render(Canvas canvas) {
    final state = notifier.snapshot;

    for (final platform in state.platforms) {
      final heightScale =
          platform.broken ? (1 - platform.breakAnim).clamp(0.0, 1.0) : 1.0;
      if (heightScale <= 0) continue;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          platform.x,
          platform.y,
          DoodleConst.platformW,
          DoodleConst.platformH * heightScale,
        ),
        const Radius.circular(8),
      );

      canvas.drawRRect(rect, Paint()..color = platform.color);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = Colors.white.withAlpha(45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      if (platform.type == DoodlePlatformType.spring) {
        final y = platform.y + DoodleConst.platformH * heightScale;
        final spring = Path()
          ..moveTo(platform.x + 26, y - 2)
          ..quadraticBezierTo(platform.x + 31, y - 8, platform.x + 36, y - 2)
          ..quadraticBezierTo(platform.x + 41, y - 8, platform.x + 46, y - 2);
        canvas.drawPath(
          spring,
          Paint()
            ..color = Colors.black.withAlpha(100)
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }
}

class _DoodleCoinRenderer extends Component {
  _DoodleCoinRenderer({required this.notifier});

  final DoodleNotifier notifier;

  @override
  void render(Canvas canvas) {
    final coins = notifier.snapshot.coins;
    for (final coin in coins) {
      final radius = 9.5 + sin(coin.pulse) * 1.2;
      canvas.drawCircle(
        Offset(coin.x, coin.y),
        radius + 4,
        Paint()..color = DoodleColors.warning.withAlpha(70),
      );
      canvas.drawCircle(
        Offset(coin.x, coin.y),
        radius,
        Paint()..color = DoodleColors.warning,
      );
    }
  }
}

class _DoodlerRenderer extends Component {
  _DoodlerRenderer({required this.notifier});

  final DoodleNotifier notifier;

  @override
  void render(Canvas canvas) {
    final state = notifier.snapshot;
    if (state.status == DoodleStatus.idle) return;

    final centerX = state.doodlerX + DoodleConst.doodlerW / 2;
    final centerY = state.doodlerY + DoodleConst.doodlerH / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    if (!state.facingRight) {
      canvas.scale(-1, 1);
    }

    final jumpStretch = state.doodlerVY < 0;
    canvas.scale(jumpStretch ? 0.93 : 1.05, jumpStretch ? 1.07 : 0.95);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: DoodleConst.doodlerW,
        height: DoodleConst.doodlerH,
      ),
      const Radius.circular(12),
    );

    canvas.drawRRect(body, Paint()..color = DoodleColors.doodlerBody);

    final eyeWhite = Paint()..color = DoodleColors.doodlerEye;
    final pupil = Paint()..color = Colors.black;
    canvas.drawCircle(const Offset(-8, -6), 4, eyeWhite);
    canvas.drawCircle(const Offset(5, -6), 4, eyeWhite);
    canvas.drawCircle(const Offset(-7, -6), 1.7, pupil);
    canvas.drawCircle(const Offset(6, -6), 1.7, pupil);

    final feet = Paint()..color = DoodleColors.doodlerFeet;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-8, 15), width: 9, height: 6),
      feet,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(8, 15), width: 9, height: 6),
      feet,
    );

    canvas.restore();
  }
}

class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
  });

  double x;
  double y;
  final double r;
  final double speed;
}
