import 'dart:math';
import 'package:flame/components.dart';

import 'package:flame/particles.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle;
import 'package:flutter/material.dart'
    show
        Canvas,
        Color,
        Colors,
        MaskFilter,
        BlurStyle,
        Paint,
        PaintingStyle,
        Rect,
        RRect,
        Radius,
        Offset,
        Path,
        TextStyle,
        DashPathEffect;
import 'flick_styles.dart';

// ─────────────────────────────────────────────
//  PUCK BODY  — physics disc
// ─────────────────────────────────────────────
class PuckBody extends BodyComponent {
  final PuckOwner owner;
  final Vector2   spawnPos;   // world px coords
  String          id;
  bool            knockedOff = false;

  // Trail effect
  final List<Vector2> _trail = [];
  static const int _trailLen = 8;

  PuckBody({
    required this.owner,
    required this.spawnPos,
    required this.id,
  });

  Color get _color =>
      owner == PuckOwner.player ? FlickColors.playerPuck : FlickColors.aiPuck;

  @override
  Body createBody() {
    final shape = CircleShape()
      ..radius = FlickConst.puckRadius / FlickConst.worldScale;

    final fixDef = FixtureDef(
      shape,
      density:     FlickConst.puckMass,
      restitution: FlickConst.puckRestitution,
      friction:    FlickConst.puckFriction,
    );

    final bodyDef = BodyDef(
      type:           BodyType.dynamic,
      position:       spawnPos / FlickConst.worldScale,
      linearDamping:  FlickConst.linearDamping,
      angularDamping: 0.8,
      bullet:         true,  // continuous collision detection
    );

    return world.createBody(bodyDef)..createFixture(fixDef);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Record trail
    if (_trail.length >= _trailLen) _trail.removeAt(0);
    _trail.add(body.position * FlickConst.worldScale);
  }

  void applyFlickImpulse(Vector2 impulse) {
    final capped = impulse.length > FlickConst.maxFlickImpulse
        ? impulse.normalized() * FlickConst.maxFlickImpulse
        : impulse;
    body.applyLinearImpulse(capped);
  }

  Vector2 get worldPx => body.position * FlickConst.worldScale;

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.scale(1 / FlickConst.worldScale);
    final r = FlickConst.puckRadius;

    // Trail
    for (int i = 0; i < _trail.length; i++) {
      final alpha = (i / _trail.length) * 0.25;
      final trailPx = _trail[i];
      final currentPx = worldPx;
      final offset = trailPx - currentPx;
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        r * 0.4 * (i / _trail.length),
        Paint()..color = _color.withValues(alpha: alpha),
      );
    }

    // Outer glow
    canvas.drawCircle(
      Offset.zero,
      r + 8,
      Paint()
        ..color = _color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Body
    canvas.drawCircle(Offset.zero, r, Paint()..color = _color);

    // Shine
    canvas.drawCircle(
      Offset(-r * 0.28, -r * 0.28),
      r * 0.32,
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    // Border
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = _color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Owner indicator dot
    canvas.drawCircle(
      Offset.zero,
      r * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    canvas.restore();
  }
}

// ─────────────────────────────────────────────
//  ARENA WALLS  — static boundary bodies
// ─────────────────────────────────────────────
class ArenaWalls extends BodyComponent {
  final double arenaL;
  final double arenaR;
  final double arenaT;
  final double arenaB;

  ArenaWalls({
    required this.arenaL,
    required this.arenaR,
    required this.arenaT,
    required this.arenaB,
  });

  @override
  Body createBody() {
    final bodyDef = BodyDef(type: BodyType.static);
    final body    = world.createBody(bodyDef);
    final ws      = FlickConst.worldScale;

    void addWall(Vector2 a, Vector2 b) {
      final shape = EdgeShape()..set(a / ws, b / ws);
      body.createFixture(FixtureDef(shape, restitution: 0.75, friction: 0.1));
    }

    // Four walls
    addWall(Vector2(arenaL, arenaT), Vector2(arenaR, arenaT)); // top
    addWall(Vector2(arenaL, arenaB), Vector2(arenaR, arenaB)); // bottom
    addWall(Vector2(arenaL, arenaT), Vector2(arenaL, arenaB)); // left
    addWall(Vector2(arenaR, arenaT), Vector2(arenaR, arenaB)); // right

    return body;
  }

  @override
  void render(Canvas canvas) {} // rendering handled by ArenaRenderer
}

// ─────────────────────────────────────────────
//  ARENA RENDERER  — visual layer
// ─────────────────────────────────────────────
class ArenaRenderer extends PositionComponent {
  final double arenaL, arenaR, arenaT, arenaB;
  final double centreY;

  ArenaRenderer({
    required this.arenaL,
    required this.arenaR,
    required this.arenaT,
    required this.arenaB,
    required this.centreY,
  });

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTRB(arenaL, arenaT, arenaR, arenaB);

    // Player zone tint (bottom half)
    canvas.drawRect(
      Rect.fromLTRB(arenaL, centreY, arenaR, arenaB),
      Paint()..color = FlickColors.playerZone,
    );

    // AI zone tint (top half)
    canvas.drawRect(
      Rect.fromLTRB(arenaL, arenaT, arenaR, centreY),
      Paint()..color = FlickColors.aiZone,
    );

    // Centre line (dashed)
    final dashPaint = Paint()
      ..color = FlickColors.centreLine
      ..strokeWidth = 2;
    const dashLen = 12.0;
    const gapLen  = 8.0;
    double x = arenaL;
    while (x < arenaR) {
      canvas.drawLine(
        Offset(x, centreY),
        Offset((x + dashLen).clamp(arenaL, arenaR), centreY),
        dashPaint,
      );
      x += dashLen + gapLen;
    }

    // Centre circle
    canvas.drawCircle(
      Offset((arenaL + arenaR) / 2, centreY),
      30,
      Paint()
        ..color = FlickColors.centreLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Arena border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()
        ..color = FlickColors.arenaBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Player label
    _drawLabel(canvas, 'YOU',
        Offset(arenaL + 12, arenaB - 20), FlickColors.playerPuck);
    _drawLabel(canvas, 'AI',
        Offset(arenaL + 12, arenaT + 20), FlickColors.aiPuck);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPaint(
      style: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 10,
        color: color.withOpacity(0.5),
        letterSpacing: 1.5,
      ),
    );
    tp.render(canvas, text, Vector2(pos.dx, pos.dy));
  }
}

// ─────────────────────────────────────────────
//  AIM LINE  — drag preview arrow
// ─────────────────────────────────────────────
class AimLine extends PositionComponent {
  Vector2? fromPx;
  Vector2? toPx;
  bool     visible = false;

  @override
  void render(Canvas canvas) {
    if (!visible || fromPx == null || toPx == null) return;

    final f = fromPx!;
    final t = toPx!;
    final delta = t - f;
    final dist  = delta.length.clamp(0.0, 120.0);
    if (dist < 8) return;

    final dir = delta.normalized();

    // Line
    final linePaint = Paint()
      ..color = FlickColors.playerPuck.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(f.x, f.y),
      Offset(f.x + dir.x * dist, f.y + dir.y * dist),
      linePaint,
    );

    // Arrow head
    final tip    = Offset(f.x + dir.x * dist, f.y + dir.y * dist);
    final angle  = atan2(dir.y, dir.x);
    final arrowPaint = Paint()
      ..color = FlickColors.playerPuck.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(tip.dx + cos(angle) * 10, tip.dy + sin(angle) * 10)
      ..lineTo(tip.dx + cos(angle + 2.4) * 8, tip.dy + sin(angle + 2.4) * 8)
      ..lineTo(tip.dx + cos(angle - 2.4) * 8, tip.dy + sin(angle - 2.4) * 8)
      ..close();
    canvas.drawPath(path, arrowPaint);

    // Power ring on puck
    final powerFrac = (dist / 120.0).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(f.x, f.y),
      FlickConst.puckRadius + 6,
      Paint()
        ..color = FlickColors.playerPuck.withOpacity(powerFrac * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

// ─────────────────────────────────────────────
//  KNOCK-OFF BURST  — particle explosion
// ─────────────────────────────────────────────
class KnockOffBurst extends ParticleSystemComponent {
  KnockOffBurst({required Vector2 position, required Color color})
      : super(
          position: position,
          particle: Particle.generate(
            count: 22,
            lifespan: 0.7,
            generator: (i) {
              final angle = (i / 22) * 2 * pi;
              final speed = 100 + Random().nextDouble() * 150;
              return AcceleratedParticle(
                speed: Vector2(cos(angle) * speed, sin(angle) * speed),
                acceleration: Vector2(0, 200),
                child: CircleParticle(
                  radius: 3 + Random().nextDouble() * 3,
                  paint: Paint()..color = color.withOpacity(0.9),
                ),
              );
            },
          ),
        );
}

// ─────────────────────────────────────────────
//  SCREEN FLASH
// ─────────────────────────────────────────────
class FlickScreenFlash extends PositionComponent {
  final double screenW, screenH;
  final Color  color;
  double       _opacity;

  FlickScreenFlash({
    required this.screenW,
    required this.screenH,
    required this.color,
    double opacity = 0.3,
  }) : _opacity = opacity;

  @override
  void update(double dt) {
    _opacity -= dt * 2.5;
    if (_opacity <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenW, screenH),
      Paint()..color = color.withOpacity(_opacity.clamp(0, 0.3)),
    );
  }
}

// ─────────────────────────────────────────────
//  BACKGROUND
// ─────────────────────────────────────────────
class FlickBackground extends Component {
  final double screenW, screenH;
  FlickBackground({required this.screenW, required this.screenH});

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenW, screenH),
      Paint()..color = FlickColors.background,
    );
  }
}

// end of file
