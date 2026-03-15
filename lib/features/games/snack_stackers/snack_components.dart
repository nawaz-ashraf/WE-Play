import 'dart:math';
import 'package:flame/components.dart' hide World;
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' hide Route, OverlayRoute;
import 'snack_styles.dart';

// ─────────────────────────────────────────────
//  FOOD BODY  — physics body for each food item
//
//  Lives in WORLD space. Positions and shapes
//  are specified in Forge2D world units (meters).
//  The camera zoom handles the visual scaling.
// ─────────────────────────────────────────────
class FoodBody extends BodyComponent {
  final FoodConfig config;
  final Vector2 spawnWorldPosition; // world coords (meters)
  final double halfW; // half-width in world units
  final double halfH; // half-height in world units

  // Tilt warning threshold (radians)
  static const double _warnAngle = 0.52; // ~30 deg

  bool _settled  = false;
  double _settleTimer = 0;
  bool get isSettled => _settled;

  bool touchedGround = false;  // true once this item falls off the platform
  bool get isDead => touchedGround;

  /// Returns true if this body is tilted dangerously
  bool get isDangerouslyTilted => !isDead && body.angle.abs() > _warnAngle;

  FoodBody({
    required this.config,
    required this.spawnWorldPosition,
    required this.halfW,
    required this.halfH,
  });

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(halfW, halfH, Vector2.zero(), 0);

    final fixtureDef = FixtureDef(
      shape,
      density:     config.density,
      restitution: config.restitution,
      friction:    config.friction,
    );

    final bodyDef = BodyDef(
      type:            BodyType.dynamic,
      position:        spawnWorldPosition.clone(),
      linearDamping:   0.3,
      angularDamping:  0.6,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_settled) {
      final speed = body.linearVelocity.length;
      if (speed < 0.05) {
        _settleTimer += dt;
        if (_settleTimer > 0.5) _settled = true;
      } else {
        _settleTimer = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // BodyComponent already transforms the canvas to the body's
    // position and rotation. We just draw centered at (0,0).
    // Sizes are in world units, but the camera zoom will scale them
    // to screen pixels automatically.
    final w = halfW * 2;
    final h = halfH * 2;
    final rect  = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(0.2));

    // Glow
    final glowPaint = Paint()
      ..color = (isDead ? Colors.red : config.border).withOpacity(isDangerouslyTilted ? 0.6 : 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.25);
    canvas.drawRRect(rrect, glowPaint);

    // Fill
    canvas.drawRRect(rrect, Paint()..color = isDead ? Colors.grey.withOpacity(0.3) : config.color);

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isDead ? Colors.grey : config.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05,
    );

    // Emoji text
    final tp = TextPaint(
      style: TextStyle(
        fontSize: min(w, h) * 0.55,
        fontFamily: 'Apple Color Emoji',
      ),
    );
    tp.render(canvas, config.emoji, Vector2(-w * 0.28, -h * 0.35));
  }
}

// ─────────────────────────────────────────────
//  STATIC PLATFORM  — ground/base
//
//  Lives in WORLD space.
// ─────────────────────────────────────────────
class StackPlatform extends BodyComponent {
  final Vector2 worldPosition;
  final double halfW; // half-width in world units
  final double halfH; // half-height in world units
  final double screenW; // needed for render sizing

  StackPlatform({
    required this.worldPosition,
    required this.halfW,
    required this.halfH,
    required this.screenW,
  });

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(halfW, halfH, Vector2.zero(), 0);
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: worldPosition.clone(),
    );
    return world.createBody(bodyDef)
      ..createFixture(FixtureDef(shape, friction: 0.85));
  }

  @override
  void render(Canvas canvas) {
    final w = halfW * 2;
    final h = halfH * 2;

    // Glow
    final glowPaint = Paint()
      ..color = StackColors.platformEdge.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.35);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: w + 0.4, height: h + 0.2),
      glowPaint,
    );

    // Platform
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        const Radius.circular(0.15),
      ),
      Paint()..color = StackColors.platform,
    );

    // Top edge stripe
    canvas.drawLine(
      Offset(-w / 2, -h / 2 + 0.05),
      Offset(w / 2, -h / 2 + 0.05),
      Paint()
        ..color = StackColors.platformEdge
        ..strokeWidth = 0.06,
    );
  }
}

// ─────────────────────────────────────────────
//  DROPPER  — slides left-right at top, releases food on tap
//
//  Lives in VIEWPORT space (screen pixels).
// ─────────────────────────────────────────────
class Dropper extends PositionComponent {
  final double screenW;
  FoodConfig config;
  double _dir = 1.0; // +1 right, -1 left

  Dropper({required this.screenW, required this.config})
      : super(
          position: Vector2(screenW / 2, 0),
          anchor: Anchor.center,
        );

  void updateConfig(FoodConfig c) => config = c;

  @override
  void update(double dt) {
    x += _dir * StackConst.dropperSpeed * dt;
    final halfW = config.width / 2 + 12;
    if (x > screenW - halfW) {
      x = screenW - halfW;
      _dir = -1;
    } else if (x < halfW) {
      x = halfW;
      _dir = 1;
    }
  }

  @override
  void render(Canvas canvas) {
    final w = config.width;
    final h = config.height;

    // Shadow under item
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, h / 2 + 4), width: w * 0.8, height: 8),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // Item preview
    final rect  = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    final glowPaint = Paint()
      ..color = config.border.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, Paint()..color = config.color);
    canvas.drawRRect(rrect, Paint()
      ..color = config.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8);

    // Emoji
    final tp = TextPaint(
      style: TextStyle(
        fontSize: min(w, h) * 0.55,
        fontFamily: 'Apple Color Emoji',
      ),
    );
    tp.render(canvas, config.emoji, Vector2(-w * 0.28, -h * 0.35));

    // Drop indicator line
    final linePaint = Paint()
      ..color = config.border.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, h / 2 + 8), const Offset(0, 800), linePaint);
  }

  /// Returns drop position in screen-pixel coordinates.
  Vector2 get dropPosition => Vector2(x, y + config.height / 2);
}

// ─────────────────────────────────────────────
//  HEIGHT METER  — left-side progress bar
//
//  Lives in VIEWPORT space (screen pixels).
// ─────────────────────────────────────────────
class HeightMeter extends PositionComponent {
  final double screenH;
  final double platformY;
  double currentHeight = 0; // px above platform
  double peakHeight    = 0;

  static const double _maxDisplay = 600.0; // px cap on bar

  HeightMeter({required this.screenH, required this.platformY})
      : super(position: Vector2(14, 0));

  @override
  void render(Canvas canvas) {
    final barH  = screenH * 0.62;
    final barTop = screenH * 0.14;
    const barW  = 6.0;

    // Track
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barTop, barW, barH),
        const Radius.circular(3),
      ),
      Paint()..color = StackColors.gridLine,
    );

    // Fill
    final fillFrac = (currentHeight / _maxDisplay).clamp(0.0, 1.0);
    final fillH    = barH * fillFrac;
    if (fillH > 0) {
      final color = fillFrac > 0.8
          ? StackColors.energy
          : fillFrac > 0.5
              ? StackColors.accent
              : StackColors.primary;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, barTop + barH - fillH, barW, fillH),
          const Radius.circular(3),
        ),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, fillFrac > 0.7 ? 4 : 0),
      );
    }

    // Height label
    final tp = TextPaint(
      style: const TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 9,
        color: StackColors.textSecondary,
      ),
    );
    tp.render(canvas, '${currentHeight.toInt()}', Vector2(-2, barTop + barH + 6));
  }
}

// ─────────────────────────────────────────────
//  BACKGROUND (grid lines only)
//
//  Lives in WORLD space. Solid background is
//  handled by game.backgroundColor().
// ─────────────────────────────────────────────
class StackBackground extends PositionComponent {
  final double screenW;
  final double screenH;
  final double zoom;

  StackBackground({
    required this.screenW,
    required this.screenH,
    required this.zoom,
  });

  @override
  void render(Canvas canvas) {
    // Convert screen dimensions to world units
    final worldW = screenW / zoom;
    final worldH = screenH / zoom;
    // Camera is centered at (0,0), so top-left in world = (-worldW/2, -worldH/2)
    final left = -worldW / 2;
    final top  = -worldH / 2;

    // Vertical guide lines in world coords
    final paint = Paint()
      ..color = StackColors.gridLine
      ..strokeWidth = 1 / zoom; // 1px in screen space
    for (double frac = 0.1; frac < 1.0; frac += 0.1) {
      final wx = left + worldW * frac;
      canvas.drawLine(Offset(wx, top), Offset(wx, top + worldH), paint);
    }
  }
}

// ─────────────────────────────────────────────
//  WOBBLE EFFECT  — shakes a component
// ─────────────────────────────────────────────
class WobbleEffect extends Effect with EffectTarget<PositionComponent> {
  WobbleEffect() : super(EffectController(duration: 0.4, repeatCount: 3));

  @override
  void apply(double progress) {
    final angle = sin(progress * pi * 4) * 0.06;
    target.angle = angle;
  }
}
