import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart'
    show
        Canvas,
        Colors,
        Curves,
        FontWeight,
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
        Shadow;
import 'flappy_styles.dart';

// ─────────────────────────────────────────────
//  BIRD
// ─────────────────────────────────────────────
class Bird extends PositionComponent {
  double velocity = 0.0;
  bool   alive    = true;
  double _wingAngle = 0.0;
  double _wobble    = 0.0;

  Bird({required double x, required double y})
      : super(
          position: Vector2(x, y),
          anchor:   Anchor.center,
        );

  void flap() {
    velocity   = FlappyConst.flapImpulse;
    _wingAngle = -0.5;
  }

  void die() {
    alive    = false;
    velocity = FlappyConst.flapImpulse * 0.4;
  }

  @override
  void update(double dt) {
    if (!alive && position.y > 2000) return;

    velocity += FlappyConst.gravity * dt;
    position.y += velocity * dt;

    // Tilt: nose up when rising, nose down when falling
    angle = (velocity / 800.0).clamp(-0.5, 1.2);

    // Wing flap animation
    _wingAngle += dt * 12;
    _wobble = sin(_wingAngle) * 0.15;
  }

  // Collision rect (slightly smaller than visual for fairness)
  Rect get hitRect => Rect.fromCenter(
        center: Offset(position.x, position.y),
        width:  FlappyConst.birdRadius * 1.4,
        height: FlappyConst.birdRadius * 1.4,
      );

  @override
  void render(Canvas canvas) {
    final r = FlappyConst.birdRadius;

    // Glow
    canvas.drawCircle(
      Offset.zero,
      r + 10,
      Paint()
        ..color = FlappyColors.birdGlow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Wing (behind body)
    final wingPath = Path()
      ..moveTo(-r * 0.3, 0)
      ..quadraticBezierTo(
        -r * 1.1, r * (0.5 + _wobble),
        -r * 0.2, r * 0.7,
      )
      ..close();
    canvas.drawPath(wingPath, Paint()..color = FlappyColors.birdWing);

    // Body
    canvas.drawCircle(Offset.zero, r, Paint()..color = FlappyColors.birdBody);

    // Eye white
    canvas.drawCircle(
      const Offset(5, -4), 5,
      Paint()..color = FlappyColors.birdEye,
    );
    // Pupil
    canvas.drawCircle(
      const Offset(6, -4), 2.5,
      Paint()..color = Colors.black,
    );
    // Eye shine
    canvas.drawCircle(
      const Offset(7, -5.5), 1,
      Paint()..color = Colors.white,
    );

    // Beak
    final beakPath = Path()
      ..moveTo(r - 2, -2)
      ..lineTo(r + 9, 1)
      ..lineTo(r - 2, 4)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = FlappyColors.birdBeak);

    // Belly shine
    canvas.drawCircle(
      const Offset(-2, 3), r * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
  }
}

// ─────────────────────────────────────────────
//  PIPE PAIR  — top + bottom pipe with gap
// ─────────────────────────────────────────────
class PipePair extends PositionComponent {
  final double screenH;
  final double groundH;
  final double gapCentre; // Y centre of the gap
  final double gapSize;
  bool scored = false;

  PipePair({
    required double x,
    required this.screenH,
    required this.groundH,
    required this.gapCentre,
    required this.gapSize,
  }) : super(position: Vector2(x, 0));

  double get rightEdge  => position.x + FlappyConst.pipeWidth;
  double get leftEdge   => position.x;
  double get gapTop     => gapCentre - gapSize / 2;
  double get gapBottom  => gapCentre + gapSize / 2;

  // Returns true if the bird rect collides with this pipe pair
  bool collidesWith(Rect birdRect) {
    final pipeLeft  = position.x;
    final pipeRight = position.x + FlappyConst.pipeWidth;

    if (birdRect.right < pipeLeft || birdRect.left > pipeRight) return false;

    // Top pipe collision
    if (birdRect.top < gapTop)    return true;
    // Bottom pipe collision
    if (birdRect.bottom > gapBottom) return true;

    return false;
  }

  @override
  void render(Canvas canvas) {
    final pipeW = FlappyConst.pipeWidth;
    final capH  = 22.0;
    final capOverhang = 8.0;

    void drawPipe(double top, double bottom) {
      final body = Rect.fromLTRB(0, top, pipeW, bottom);

      // Glow
      canvas.drawRect(
        body.inflate(6),
        Paint()
          ..color = FlappyColors.pipeGlow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Body
      canvas.drawRect(body, Paint()..color = FlappyColors.pipeBody);

      // Inner highlight
      canvas.drawRect(
        Rect.fromLTRB(4, top, 14, bottom),
        Paint()..color = FlappyColors.pipeEdge.withValues(alpha: 0.12),
      );

      // Border
      canvas.drawRect(
        body,
        Paint()
          ..color = FlappyColors.pipeEdge.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    void drawCap(double y, bool isTop) {
      final capRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          -capOverhang, isTop ? y - capH : y,
          pipeW + capOverhang, isTop ? y : y + capH,
        ),
        const Radius.circular(4),
      );

      // Glow
      canvas.drawRRect(
        capRect,
        Paint()
          ..color = FlappyColors.pipeGlow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Cap body
      canvas.drawRRect(capRect, Paint()..color = FlappyColors.pipeCap);

      // Cap border
      canvas.drawRRect(
        capRect,
        Paint()
          ..color = FlappyColors.pipeEdge.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Top pipe (from screen top to gap top)
    drawPipe(0, gapTop);
    drawCap(gapTop, true);

    // Bottom pipe (from gap bottom to ground)
    drawPipe(gapBottom, screenH - groundH);
    drawCap(gapBottom, false);
  }
}

// ─────────────────────────────────────────────
//  GROUND  — scrolling floor
// ─────────────────────────────────────────────
class Ground extends PositionComponent {
  final double screenW;
  final double screenH;
  double _scrollX = 0.0;
  double speed    = FlappyConst.pipeSpeedBase;

  Ground({required this.screenW, required this.screenH})
      : super(position: Vector2.zero());

  @override
  void update(double dt) {
    _scrollX = (_scrollX + speed * dt) % 40;
  }

  @override
  void render(Canvas canvas) {
    final groundY = screenH - FlappyConst.groundH;

    // Ground fill
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, screenW, FlappyConst.groundH),
      Paint()..color = FlappyColors.groundTop,
    );

    // Top edge line
    canvas.drawLine(
      Offset(0, groundY),
      Offset(screenW, groundY),
      Paint()
        ..color = FlappyColors.pipeEdge.withValues(alpha: 0.4)
        ..strokeWidth = 2,
    );

    // Scrolling dashes
    final dashPaint = Paint()
      ..color = FlappyColors.groundLine
      ..strokeWidth = 1;
    for (double x = -_scrollX; x < screenW; x += 40) {
      canvas.drawLine(
        Offset(x, groundY + 16),
        Offset(x + 20, groundY + 16),
        dashPaint,
      );
    }
  }
}

// ─────────────────────────────────────────────
//  BACKGROUND  — parallax stars + sky
// ─────────────────────────────────────────────
class FlappyBackground extends Component {
  final double screenW, screenH;
  final List<StarData> _stars = [];
  double _scrollOffset = 0;

  FlappyBackground({required this.screenW, required this.screenH}) {
    final rng = Random(42);
    for (int i = 0; i < 60; i++) {
      _stars.add(StarData(
        x:       rng.nextDouble() * screenW,
        y:       rng.nextDouble() * screenH * 0.75,
        radius:  0.5 + rng.nextDouble() * 1.5,
        opacity: 0.3 + rng.nextDouble() * 0.6,
      ));
    }
  }

  void scroll(double dt, double speed) {
    _scrollOffset = (_scrollOffset + speed * 0.15 * dt) % screenW;
  }

  @override
  void render(Canvas canvas) {
    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenW, screenH),
      Paint()..color = FlappyColors.background,
    );

    // Stars (parallax slow scroll)
    for (final s in _stars) {
      final sx = (s.x - _scrollOffset * 0.3) % screenW;
      canvas.drawCircle(
        Offset(sx, s.y),
        s.radius,
        Paint()..color = FlappyColors.star.withValues(alpha: s.opacity),
      );
    }

    // Horizon glow
    canvas.drawRect(
      Rect.fromLTWH(0, screenH * 0.55, screenW, screenH * 0.1),
      Paint()
        ..color = FlappyColors.primary.withValues(alpha: 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }
}

// ─────────────────────────────────────────────
//  SCORE POPUP  — "+1" floats up on score
// ─────────────────────────────────────────────
class ScorePopup extends TextComponent {
  double _timer = 0;

  ScorePopup({required Vector2 position})
      : super(
          text: '+1',
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: FlappyColors.accent,
              shadows: [Shadow(color: FlappyColors.accent, blurRadius: 10)],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(MoveByEffect(
      Vector2(0, -60),
      EffectController(duration: 0.7, curve: Curves.easeOut),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    
    // Start fading out after 0.2s, taking 0.5s to fade totally
    if (_timer > 0.2) {
      double fadeProgress = (_timer - 0.2) / 0.5;
      if (fadeProgress > 1.0) {
        removeFromParent();
      } else {
        double opacity = 1.0 - fadeProgress;
        textRenderer = TextPaint(
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: FlappyColors.accent.withValues(alpha: opacity),
            shadows: [Shadow(color: FlappyColors.accent.withValues(alpha: opacity), blurRadius: 10)],
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────
//  DEATH BURST  — particle explosion on die
// ─────────────────────────────────────────────
class DeathBurst extends ParticleSystemComponent {
  DeathBurst({required Vector2 position})
      : super(
          position: position,
          particle: Particle.generate(
            count: 24,
            lifespan: 0.8,
            generator: (i) {
              final angle = (i / 24) * 2 * pi;
              final speed = 80.0 + Random().nextDouble() * 180;
              return AcceleratedParticle(
                speed: Vector2(cos(angle) * speed, sin(angle) * speed),
                acceleration: Vector2(0, 400),
                child: CircleParticle(
                  radius: 2 + Random().nextDouble() * 4,
                  paint: Paint()
                    ..color = FlappyColors.birdBody.withValues(alpha: 0.9),
                ),
              );
            },
          ),
        );
}

// ─────────────────────────────────────────────
//  SCREEN FLASH
// ─────────────────────────────────────────────
class FlappyFlash extends PositionComponent {
  final double screenW, screenH;
  double _opacity;

  FlappyFlash({
    required this.screenW,
    required this.screenH,
    double opacity = 0.5,
  }) : _opacity = opacity;

  @override
  void update(double dt) {
    _opacity -= dt * 3;
    if (_opacity <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenW, screenH),
      Paint()..color = FlappyColors.energy.withValues(alpha: _opacity.clamp(0, 0.5)),
    );
  }
}
