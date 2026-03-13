import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'beat_crash_styles.dart';

// ─────────────────────────────────────────────
//  BEAT BLOCK  — falls from top → target zone
// ─────────────────────────────────────────────
class BeatBlock extends PositionComponent {
  final int lane;
  final double fallDuration; // seconds to reach target
  final double targetY;      // Y position of target zone centre
  final void Function(BeatBlock) onReachTarget;

  late final Paint _paint;
  late final Paint _glowPaint;
  final Color _color;
  double _elapsed = 0;
  bool _hit = false;
  bool _passed = false;

  BeatBlock({
    required this.lane,
    required this.fallDuration,
    required this.targetY,
    required this.onReachTarget,
    required double startX,
    required double blockW,
    required double startY,
    required Color color,
  })  : _color = color,
        super(
          position: Vector2(startX, startY),
          size: Vector2(blockW, BeatConst.blockHeight),
          anchor: Anchor.center,
        ) {
    _paint = Paint()..color = _color;
    _glowPaint = Paint()
      ..color = _color.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  }

  /// How far past the target this block is (seconds).
  /// Positive = block is below target / overdue.
  double get timePastTarget => _elapsed - fallDuration;

  bool get isHit    => _hit;
  bool get isPassed => _passed;

  void markHit() => _hit = true;

  @override
  void update(double dt) {
    if (_hit) return;
    _elapsed += dt;
    // Move from startY to targetY over fallDuration
    final progress = (_elapsed / fallDuration).clamp(0.0, 1.5);
    y = -size.y + (targetY + size.y / 2) * progress;

    if (!_passed && timePastTarget > BeatConst.goodWindow) {
      _passed = true;
      onReachTarget(this); // auto-miss
    }
  }

  @override
  void render(Canvas canvas) {
    if (_hit) return;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rrect, _glowPaint);
    canvas.drawRRect(rrect, _paint);
    // Inner shine
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y * 0.35),
        const Radius.circular(6),
      ),
      shinePaint,
    );
  }
}

// ─────────────────────────────────────────────
//  TARGET ZONE  — static bar at bottom
// ─────────────────────────────────────────────
class TargetZone extends PositionComponent {
  final double screenWidth;
  bool _pulse = false;
  double _pulseTimer = 0;
  Color _pulseColor = BeatColors.primary;

  TargetZone({required this.screenWidth, required double y})
      : super(
          position: Vector2(0, y),
          size: Vector2(screenWidth, 4),
          anchor: Anchor.center,
        );

  void pulse(Color color) {
    _pulse = true;
    _pulseColor = color;
    _pulseTimer = 0.25;
  }

  @override
  void update(double dt) {
    if (_pulseTimer > 0) {
      _pulseTimer -= dt;
      if (_pulseTimer <= 0) _pulse = false;
    }
  }

  @override
  void render(Canvas canvas) {
    // Glow
    final glowPaint = Paint()
      ..color = (_pulse ? _pulseColor : BeatColors.primary).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRect(Rect.fromLTWH(-8, -8, size.x + 16, size.y + 16), glowPaint);

    // Line
    final linePaint = Paint()
      ..color = _pulse ? _pulseColor : BeatColors.primary
      ..strokeWidth = _pulse ? 3 : 2;
    canvas.drawLine(Offset(0, size.y / 2), Offset(size.x, size.y / 2), linePaint);

    // Lane separators
    final sepPaint = Paint()..color = Colors.white.withOpacity(0.05);
    final laneW = size.x / BeatConst.lanes;
    for (int i = 1; i < BeatConst.lanes; i++) {
      canvas.drawLine(
        Offset(laneW * i, -200),
        Offset(laneW * i, 200),
        sepPaint,
      );
    }
  }
}

// ─────────────────────────────────────────────
//  PARTICLE BURST  — spawns on hit
// ─────────────────────────────────────────────
class HitParticleBurst extends ParticleSystemComponent {
  HitParticleBurst({
    required Vector2 position,
    required Color color,
  }) : super(
          position: position,
          particle: Particle.generate(
            count: 18,
            lifespan: 0.55,
            generator: (i) {
              final angle  = (i / 18) * 2 * pi;
              final speed  = 80 + Random().nextDouble() * 120;
              return AcceleratedParticle(
                speed: Vector2(cos(angle) * speed, sin(angle) * speed),
                acceleration: Vector2(0, 180),
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
//  HIT LABEL  — "PERFECT / GOOD / MISS" flash
//  Manual opacity fade (TextComponent doesn't
//  implement OpacityProvider for OpacityEffect).
// ─────────────────────────────────────────────
class HitLabel extends PositionComponent {
  final String _text;
  final Color _color;
  double _opacity = 1.0;
  double _elapsed = 0;
  static const _fadeDuration = 0.7;

  HitLabel({
    required String text,
    required Color color,
    required Vector2 position,
  })  : _text = text,
        _color = color,
        super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Float up
    add(MoveByEffect(
      Vector2(0, -60),
      EffectController(duration: _fadeDuration, curve: Curves.easeOut),
    ));
    // Quick scale pop
    add(ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(duration: 0.15),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _opacity = (1.0 - _elapsed / _fadeDuration).clamp(0.0, 1.0);
    if (_elapsed >= _fadeDuration + 0.1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final style = TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: _color.withOpacity(_opacity),
      shadows: [
        Shadow(
          color: _color.withOpacity(_opacity * 0.8),
          blurRadius: 16,
        ),
      ],
    );
    final tp = TextPaint(style: style);
    tp.render(canvas, _text, Vector2.zero(), anchor: Anchor.center);
  }
}

// ─────────────────────────────────────────────
//  BACKGROUND  — scrolling dark grid
// ─────────────────────────────────────────────
class BeatBackground extends Component {
  final double screenW;
  final double screenH;
  double _scrollY = 0;

  BeatBackground({required this.screenW, required this.screenH});

  @override
  void update(double dt) {
    _scrollY = (_scrollY + dt * 40) % 60;
  }

  @override
  void render(Canvas canvas) {
    // Base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenW, screenH),
      Paint()..color = BeatColors.background,
    );
    // Grid lines
    final gridPaint = Paint()
      ..color = BeatColors.primary.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double y = -60 + _scrollY; y < screenH; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(screenW, y), gridPaint);
    }
    for (double x = 0; x < screenW; x += screenW / BeatConst.lanes) {
      canvas.drawLine(Offset(x, 0), Offset(x, screenH), gridPaint);
    }
  }
}

// ─────────────────────────────────────────────
//  SCREEN FLASH  — full-screen tint on miss
// ─────────────────────────────────────────────
class ScreenFlash extends PositionComponent {
  final Color color;
  double _opacity;

  ScreenFlash({
    required double screenW,
    required double screenH,
    required this.color,
    double opacity = 0.25,
  })  : _opacity = opacity,
        super(size: Vector2(screenW, screenH));

  @override
  void update(double dt) {
    _opacity -= dt * 3;
    if (_opacity <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = color.withOpacity(_opacity.clamp(0, 1)),
    );
  }
}
