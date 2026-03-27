import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_switch_provider.dart';
import 'color_switch_styles.dart';

// ─────────────────────────────────────────────
//  COLOR SWITCH TAP – FLAME RENDERER
// ─────────────────────────────────────────────

class ColorSwitchGame extends FlameGame with TapCallbacks {
  final CSNotifier notifier;
  ColorSwitchGame({required this.notifier});

  @override
  Color backgroundColor() => CSColors.background;

  void startGame() {
    Future.microtask(() => notifier.startGame(size.y));
  }

  @override
  void update(double dt) {
    super.update(dt);
    Future.microtask(() => notifier.tick(dt, size.y));
  }

  @override
  void onTapDown(TapDownEvent event) {
    Future.microtask(() => notifier.tap());
    HapticFeedback.lightImpact();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final state = notifier.state;
    if (state.status == CSStatus.idle) return;

    final cx = size.x / 2;

    // ── obstacles ─────────────────────────────
    for (final o in state.obstacles) {
      _drawObstacle(canvas, cx, o.y, o.rotation);
    }

    // ── colour switchers ──────────────────────
    for (final s in state.switchers) {
      if (!s.consumed) {
        _drawSwitcher(canvas, cx, s.y);
      }
    }

    // ── ball ──────────────────────────────────
    _drawBall(canvas, cx, state.ballY, state.ballColor);
  }

  // ─────── draw helpers ───────────────────────

  void _drawObstacle(Canvas canvas, double cx, double cy, double rotation) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);

    final outer = CSConst.obstacleRadius;
    final inner = outer - CSConst.obstacleThickness;

    for (int i = 0; i < 4; i++) {
      final startAngle = (i / 4) * 2 * pi - pi / 4;
      final sweep = pi / 2;

      // Outer filled arc
      final outerRect = Rect.fromCircle(center: Offset.zero, radius: outer);
      final paint = Paint()
        ..color = CSColors.gameColors[i]
        ..style = PaintingStyle.fill;
      canvas.drawArc(outerRect, startAngle, sweep, true, paint);
    }

    // Punch out inner circle
    canvas.drawCircle(
      Offset.zero,
      inner,
      Paint()..color = CSColors.background,
    );

    // Thin dark seam lines between segments
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * pi - pi / 4;
      final dx = cos(angle);
      final dy = sin(angle);
      canvas.drawLine(
        Offset(dx * inner, dy * inner),
        Offset(dx * outer, dy * outer),
        Paint()
          ..color = CSColors.background
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke,
      );
    }

    canvas.restore();
  }

  void _drawSwitcher(Canvas canvas, double cx, double y) {
    final r = CSConst.switcherRadius;

    // Rotating 4-colour mini circle
    for (int i = 0; i < 4; i++) {
      final startAngle = (i / 4) * 2 * pi;
      final rect = Rect.fromCircle(center: Offset(cx, y), radius: r);
      canvas.drawArc(
        rect,
        startAngle,
        pi / 2,
        true,
        Paint()..color = CSColors.gameColors[i],
      );
    }

    // White outline
    canvas.drawCircle(
      Offset(cx, y),
      r + 1,
      Paint()
        ..color = Colors.white.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawBall(Canvas canvas, double cx, double y, Color color) {
    // Outer glow
    canvas.drawCircle(
      Offset(cx, y),
      CSConst.ballRadius + 10,
      Paint()..color = color.withAlpha(30),
    );
    // Main body
    canvas.drawCircle(
      Offset(cx, y),
      CSConst.ballRadius,
      Paint()..color = color,
    );
    // White highlight
    canvas.drawCircle(
      Offset(cx - 4, y - 4),
      4,
      Paint()..color = Colors.white.withAlpha(140),
    );
  }
}
