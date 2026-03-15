import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart'
    show
        Canvas,
        Color,
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
        StrokeCap,
        TextStyle,
        Offset,
        Path,
        Shadow;
import 'heist_styles.dart';

// ─────────────────────────────────────────────
//  GRID MAP  — renders walls and floor tiles
// ─────────────────────────────────────────────
class GridMap extends PositionComponent {
  final List<List<CellType>> cells;
  final double cs; // cell size px

  GridMap({required this.cells, required this.cs, required Vector2 offset})
      : super(position: offset);

  @override
  void render(Canvas canvas) {
    for (int r = 0; r < cells.length; r++) {
      for (int c = 0; c < cells[r].length; c++) {
        final rect = Rect.fromLTWH(c * cs, r * cs, cs, cs);
        final cell = cells[r][c];

        switch (cell) {
          case CellType.wall:
            // Wall fill
            canvas.drawRect(rect, Paint()..color = HeistColors.cellWall);
            // Wall edge highlight
            canvas.drawRect(
              rect,
              Paint()
                ..color = HeistColors.cellWallEdge
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.5,
            );
            break;

          case CellType.floor:
          case CellType.loot:
          case CellType.exit:
            // Floor
            canvas.drawRect(rect, Paint()..color = HeistColors.cellFloor);
            // Subtle grid dot
            canvas.drawCircle(
              Offset(c * cs + cs / 2, r * cs + cs / 2),
              1.0,
              Paint()..color = HeistColors.cellWallEdge.withOpacity(0.4),
            );
            break;
        }
      }
    }
  }
}

// ─────────────────────────────────────────────
//  THIEF SPRITE  — player character on grid
// ─────────────────────────────────────────────
class ThiefSprite extends PositionComponent {
  final double cs;
  bool hasLoot = false;
  int  facingDir = 0; // 0=right 1=left 2=up 3=down

  ThiefSprite({required this.cs, required int row, required int col, required Vector2 gridOffset})
      : super(
          position: Vector2(
            gridOffset.x + col * cs + cs / 2,
            gridOffset.y + row * cs + cs / 2,
          ),
          anchor: Anchor.center,
        );

  void moveTo(int row, int col, Vector2 gridOffset) {
    final target = Vector2(
      gridOffset.x + col * cs + cs / 2,
      gridOffset.y + row * cs + cs / 2,
    );
    add(MoveToEffect(
      target,
      EffectController(duration: 0.12, curve: Curves.easeOut),
    ));
  }

  @override
  void render(Canvas canvas) {
    final r = HeistConst.thiefSize / 2;

    // Glow
    canvas.drawCircle(
      Offset.zero,
      r + 6,
      Paint()
        ..color = (hasLoot ? HeistColors.warn : HeistColors.cellThief).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Body circle
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = hasLoot ? HeistColors.warn : HeistColors.cellThief,
    );

    // Hat / beret
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -r + 4), width: r * 1.2, height: r * 0.5),
        const Radius.circular(3),
      ),
      Paint()..color = hasLoot ? const Color(0xFF997700) : const Color(0xFF4433BB),
    );

    // Eyes
    final eyeY = -2.0;
    canvas.drawCircle(Offset(-4, eyeY), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(4,  eyeY), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(-4, eyeY), 1.2, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(4,  eyeY), 1.2, Paint()..color = Colors.black);

    // Loot bag
    if (hasLoot) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, r - 4), width: 12, height: 10),
          const Radius.circular(3),
        ),
        Paint()..color = HeistColors.warn,
      );
      final tp = TextPaint(style: const TextStyle(fontSize: 8));
      tp.render(canvas, '\$', Vector2(-3, r - 9));
    }
  }
}

// ─────────────────────────────────────────────
//  LOOT ITEM  — pulsing gold briefcase
// ─────────────────────────────────────────────
class LootItem extends PositionComponent {
  final double cs;
  double _pulse = 0;
  bool   collected = false;

  LootItem({required this.cs, required int row, required int col, required Vector2 gridOffset})
      : super(
          position: Vector2(
            gridOffset.x + col * cs + cs / 2,
            gridOffset.y + row * cs + cs / 2,
          ),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    _pulse += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;
    final glow = 0.4 + sin(_pulse) * 0.25;
    final s    = HeistConst.lootSize;

    // Glow
    canvas.drawCircle(
      Offset.zero,
      s,
      Paint()
        ..color = HeistColors.cellLoot.withOpacity(glow * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Briefcase body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s * 1.2, height: s * 0.85),
        const Radius.circular(4),
      ),
      Paint()..color = HeistColors.cellLoot,
    );

    // Handle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -s * 0.5), width: s * 0.45, height: s * 0.25),
        const Radius.circular(3),
      ),
      Paint()
        ..color = HeistColors.cellLoot
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // $ symbol
    final tp = TextPaint(
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0A0A12),
      ),
    );
    tp.render(canvas, '\$', Vector2(-4, -7));
  }

  void collect() {
    collected = true;
    add(ScaleEffect.to(
      Vector2.zero(),
      EffectController(duration: 0.2),
      onComplete: removeFromParent,
    ));

    // Particle burst
    parent?.add(ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 14,
        lifespan: 0.6,
        generator: (i) {
          final angle = (i / 14) * 2 * pi;
          return AcceleratedParticle(
            speed: Vector2(cos(angle) * 80, sin(angle) * 80),
            acceleration: Vector2(0, 100),
            child: CircleParticle(
              radius: 3,
              paint: Paint()..color = HeistColors.cellLoot.withOpacity(0.9),
            ),
          );
        },
      ),
    ));
  }
}

// ─────────────────────────────────────────────
//  EXIT DOOR  — animated green portal
// ─────────────────────────────────────────────
class ExitDoor extends PositionComponent {
  final double cs;
  double _pulse = 0;
  bool   active = false; // becomes active after loot collected

  ExitDoor({required this.cs, required int row, required int col, required Vector2 gridOffset})
      : super(
          position: Vector2(
            gridOffset.x + col * cs + cs / 2,
            gridOffset.y + row * cs + cs / 2,
          ),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    _pulse += dt * (active ? 4 : 1.5);
  }

  @override
  void render(Canvas canvas) {
    final glow = active ? 0.5 + sin(_pulse) * 0.3 : 0.15 + sin(_pulse) * 0.05;
    final s    = cs * 0.45;
    final color = active ? HeistColors.cellExit : HeistColors.cellExit.withOpacity(0.35);

    // Glow ring
    canvas.drawCircle(
      Offset.zero,
      s + 8,
      Paint()
        ..color = color.withOpacity(glow * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Door shape
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s * 1.5, height: s * 1.8),
        Radius.circular(s * 0.4),
      ),
      Paint()..color = color.withOpacity(active ? 1.0 : 0.3),
    );

    // Arrow
    if (active) {
      final arrowPaint = Paint()
        ..color = HeistColors.background
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(-6, 0)
        ..lineTo(6, 0)
        ..moveTo(2, -4)
        ..lineTo(6, 0)
        ..lineTo(2, 4);
      canvas.drawPath(path, arrowPaint);
    }
  }
}

// ─────────────────────────────────────────────
//  LASER BEAM  — sweeping line
// ─────────────────────────────────────────────
class LaserBeam extends PositionComponent {
  final LaserDef def;
  final double   cs;
  final Vector2  gridOffset;
  final double   speed;        // cells per second
  double         _progress;    // 0.0 → 1.0 along sweep range, bounces
  int            _dir = 1;     // +1 or -1

  /// Current tip position in grid cols/rows (fractional)
  double get _tipIndex =>
      def.sweepStart + _progress * (def.sweepEnd - def.sweepStart);

  LaserBeam({
    required this.def,
    required this.cs,
    required this.gridOffset,
    required this.speed,
  }) : _progress = def.phase,
       super(position: Vector2.zero());

  @override
  void update(double dt) {
    final range = (def.sweepEnd - def.sweepStart).toDouble();
    _progress += _dir * (speed / range) * dt;
    if (_progress >= 1.0) { _progress = 1.0; _dir = -1; }
    if (_progress <= 0.0) { _progress = 0.0; _dir =  1; }
  }

  /// Returns the world rect of the laser beam (for hit detection)
  Rect get worldRect {
    final tip = _tipIndex;
    if (def.axis == LaserAxis.horizontal) {
      final y  = gridOffset.y + def.fixedIndex * cs + cs / 2;
      final x1 = gridOffset.x + def.sweepStart * cs + cs / 2;
      final x2 = gridOffset.x + tip * cs + cs / 2;
      return Rect.fromLTRB(
        x1 - 2, y - HeistConst.laserWidth,
        x2 + 2, y + HeistConst.laserWidth,
      );
    } else {
      final x  = gridOffset.x + def.fixedIndex * cs + cs / 2;
      final y1 = gridOffset.y + def.sweepStart * cs + cs / 2;
      final y2 = gridOffset.y + tip * cs + cs / 2;
      return Rect.fromLTRB(
        x - HeistConst.laserWidth, y1 - 2,
        x + HeistConst.laserWidth, y2 + 2,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final tip = _tipIndex;

    if (def.axis == LaserAxis.horizontal) {
      final y  = def.fixedIndex * cs + cs / 2 + gridOffset.y - position.y;
      final x1 = def.sweepStart * cs + cs / 2 + gridOffset.x - position.x;
      final x2 = tip * cs + cs / 2 + gridOffset.x - position.x;

      // Glow
      canvas.drawLine(
        Offset(x1, y), Offset(x2, y),
        Paint()
          ..color = HeistColors.laserGlow
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Core
      canvas.drawLine(
        Offset(x1, y), Offset(x2, y),
        Paint()
          ..color = HeistColors.laser
          ..strokeWidth = HeistConst.laserWidth,
      );
      // Origin dot
      canvas.drawCircle(Offset(x1, y), 4, Paint()..color = HeistColors.laser);
      // Tip dot
      canvas.drawCircle(
        Offset(x2, y), 5,
        Paint()
          ..color = HeistColors.laser
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    } else {
      final x  = def.fixedIndex * cs + cs / 2 + gridOffset.x - position.x;
      final y1 = def.sweepStart * cs + cs / 2 + gridOffset.y - position.y;
      final y2 = tip * cs + cs / 2 + gridOffset.y - position.y;

      canvas.drawLine(
        Offset(x, y1), Offset(x, y2),
        Paint()
          ..color = HeistColors.laserGlow
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawLine(
        Offset(x, y1), Offset(x, y2),
        Paint()
          ..color = HeistColors.laser
          ..strokeWidth = HeistConst.laserWidth,
      );
      canvas.drawCircle(Offset(x, y1), 4, Paint()..color = HeistColors.laser);
      canvas.drawCircle(
        Offset(x, y2), 5,
        Paint()
          ..color = HeistColors.laser
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }
}

// ─────────────────────────────────────────────
//  BUSTED FLASH  — red overlay on death
// ─────────────────────────────────────────────
class BustedFlash extends PositionComponent {
  final double screenW;
  final double screenH;
  double _opacity = 0.7;

  BustedFlash({required this.screenW, required this.screenH})
      : super(size: Vector2(0, 0));

  @override
  void update(double dt) {
    _opacity -= dt * 1.8;
    if (_opacity <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenW, screenH),
      Paint()..color = HeistColors.energy.withOpacity(_opacity.clamp(0, 0.7)),
    );
  }
}

// ─────────────────────────────────────────────
//  BACKGROUND  — dark ambient
// ─────────────────────────────────────────────
class HeistBackground extends Component {
  final double screenW;
  final double screenH;

  HeistBackground({required this.screenW, required this.screenH});

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenW, screenH),
      Paint()..color = HeistColors.background,
    );
  }
}
