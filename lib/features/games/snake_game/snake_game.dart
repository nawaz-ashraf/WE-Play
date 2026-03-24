import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart'
    show
        Canvas,
        Color,
        Colors,
        FontWeight,
        MaskFilter,
        BlurStyle,
        Paint,
        PaintingStyle,
        Path,
        Rect,
        RRect,
        Radius,
        Offset,
        TextStyle,
        Shadow,
        StrokeCap;
import 'package:flutter/services.dart' show HapticFeedback;
import 'snake_provider.dart';
import 'snake_styles.dart';

// ─────────────────────────────────────────────
//  SNAKE GAME  (FlameGame)
// ─────────────────────────────────────────────
class SnakeGame extends FlameGame with TapCallbacks {
  final SnakeNotifier notifier;

  SnakeGame({required this.notifier});

  late double _screenW, _screenH;
  late double _gridOffsetX, _gridOffsetY;
  late double _cs; // cell size (auto-fit)

  late _GridRenderer  _grid;
  late _SnakeRenderer _snakeRenderer;
  late _FoodRenderer  _foodRenderer;
  late _BgRenderer    _bg;

  bool _started = false;

  // Swipe detection
  Vector2? _swipeStart;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _screenW = size.x;
    _screenH = size.y;

    // Auto-fit cell size so grid fills ~85% of screen width
    _cs = (_screenW * 0.92) / SnakeConst.cols;
    final gridW = _cs * SnakeConst.cols;
    final gridH = _cs * SnakeConst.rows;
    _gridOffsetX = (_screenW - gridW) / 2;
    _gridOffsetY = (_screenH - gridH) / 2;

    _bg = _BgRenderer(
      screenW: _screenW, screenH: _screenH,
      gridOffsetX: _gridOffsetX, gridOffsetY: _gridOffsetY,
      gridW: gridW, gridH: gridH,
      cs: _cs,
    );
    add(_bg);

    _grid = _GridRenderer(
      offsetX: _gridOffsetX, offsetY: _gridOffsetY, cs: _cs);
    add(_grid);

    _foodRenderer  = _FoodRenderer(offsetX: _gridOffsetX, offsetY: _gridOffsetY, cs: _cs);
    add(_foodRenderer);

    _snakeRenderer = _SnakeRenderer(offsetX: _gridOffsetX, offsetY: _gridOffsetY, cs: _cs);
    add(_snakeRenderer);
  }

  void startGame() {
    _started = true;
    notifier.startGame();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_started) return;

    final prevStatus = notifier.state.status;
    final prevEaten  = notifier.state.lastEaten;

    notifier.tick(dt);

    final state = notifier.state;

    // Sync renderers
    _snakeRenderer.snake  = state.snake;
    _snakeRenderer.dir    = state.direction;
    _foodRenderer.foods   = state.foods;

    // Eat particle
    if (state.lastEaten != null && state.lastEaten != prevEaten) {
      _spawnEatParticle(state);
      HapticFeedback.lightImpact();
    }

    // Death flash
    if (state.status == SnakeStatus.dead &&
        prevStatus != SnakeStatus.dead) {
      add(_DeathFlash(screenW: _screenW, screenH: _screenH));
      HapticFeedback.heavyImpact();
    }
  }

  void _spawnEatParticle(SnakeState state) {
    if (state.snake.isEmpty) return;
    final head = state.snake.first;
    final cx   = _gridOffsetX + head.x * _cs + _cs / 2;
    final cy   = _gridOffsetY + head.y * _cs + _cs / 2;
    final color= state.lastEaten?.color ?? SnakeColors.primary;

    add(ParticleSystemComponent(
      position: Vector2(cx, cy),
      particle: Particle.generate(
        count: 14,
        lifespan: 0.5,
        generator: (i) {
          final angle = (i / 14) * 2 * pi;
          final speed = 60.0 + Random().nextDouble() * 80;
          return AcceleratedParticle(
            speed: Vector2(cos(angle) * speed, sin(angle) * speed),
            acceleration: Vector2(0, 120),
            child: CircleParticle(
              radius: 2 + Random().nextDouble() * 2,
              paint: Paint()..color = color.withOpacity(0.9),
            ),
          );
        },
      ),
    ));
  }

  // ── Tap / swipe input ─────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    _swipeStart = event.localPosition;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_swipeStart == null) return;
    final delta = event.localPosition - _swipeStart!;
    _swipeStart = null;
    if (delta.length < 12) return; // too short

    final dx = delta.x.abs();
    final dy = delta.y.abs();
    if (dx > dy) {
      notifier.setDirection(
          delta.x > 0 ? SnakeDirection.right : SnakeDirection.left);
    } else {
      notifier.setDirection(
          delta.y > 0 ? SnakeDirection.down : SnakeDirection.up);
    }
  }

  // Public swipe API (called from D-Pad)
  void swipeUp()    => notifier.setDirection(SnakeDirection.up);
  void swipeDown()  => notifier.setDirection(SnakeDirection.down);
  void swipeLeft()  => notifier.setDirection(SnakeDirection.left);
  void swipeRight() => notifier.setDirection(SnakeDirection.right);
}

// ─────────────────────────────────────────────
//  BACKGROUND RENDERER
// ─────────────────────────────────────────────
class _BgRenderer extends Component {
  final double screenW, screenH, gridOffsetX, gridOffsetY, gridW, gridH, cs;
  _BgRenderer({
    required this.screenW, required this.screenH,
    required this.gridOffsetX, required this.gridOffsetY,
    required this.gridW, required this.gridH, required this.cs,
  });

  @override
  void render(Canvas canvas) {
    // Full background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenW, screenH),
      Paint()..color = SnakeColors.background,
    );

    // Grid background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(gridOffsetX, gridOffsetY, gridW, gridH),
        const Radius.circular(12),
      ),
      Paint()..color = SnakeColors.gridBg,
    );

    // Grid lines
    final linePaint = Paint()
      ..color = SnakeColors.gridLine
      ..strokeWidth = 0.5;

    for (int x = 0; x <= SnakeConst.cols; x++) {
      canvas.drawLine(
        Offset(gridOffsetX + x * cs, gridOffsetY),
        Offset(gridOffsetX + x * cs, gridOffsetY + gridH),
        linePaint,
      );
    }
    for (int y = 0; y <= SnakeConst.rows; y++) {
      canvas.drawLine(
        Offset(gridOffsetX, gridOffsetY + y * cs),
        Offset(gridOffsetX + gridW, gridOffsetY + y * cs),
        linePaint,
      );
    }
  }
}

// ─────────────────────────────────────────────
//  GRID RENDERER  (border only)
// ─────────────────────────────────────────────
class _GridRenderer extends Component {
  final double offsetX, offsetY, cs;
  _GridRenderer({required this.offsetX, required this.offsetY, required this.cs});

  @override
  void render(Canvas canvas) {
    final gridW = cs * SnakeConst.cols;
    final gridH = cs * SnakeConst.rows;

    // Glow border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(offsetX, offsetY, gridW, gridH),
        const Radius.circular(12),
      ),
      Paint()
        ..color = SnakeColors.primary.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(offsetX, offsetY, gridW, gridH),
        const Radius.circular(12),
      ),
      Paint()
        ..color = SnakeColors.primary.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

// ─────────────────────────────────────────────
//  SNAKE RENDERER
// ─────────────────────────────────────────────
class _SnakeRenderer extends Component {
  List<Point>     snake = [];
  SnakeDirection  dir   = SnakeDirection.up;
  final double    offsetX, offsetY, cs;

  _SnakeRenderer({required this.offsetX, required this.offsetY, required this.cs});

  @override
  void render(Canvas canvas) {
    if (snake.isEmpty) return;

    for (int i = 0; i < snake.length; i++) {
      final p      = snake[i];
      final isHead = i == 0;
      final frac   = 1 - (i / snake.length); // 1 at head → 0 at tail
      final rect   = Rect.fromLTWH(
        offsetX + p.x * cs + 1,
        offsetY + p.y * cs + 1,
        cs - 2, cs - 2,
      );
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cs * 0.3));

      // Glow on head
      if (isHead) {
        canvas.drawRRect(
          rrect.inflate(4),
          Paint()
            ..color = SnakeColors.snakeHeadGlow
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      // Body color gradient head→tail
      final Color bodyColor = isHead
          ? SnakeColors.snakeHead
          : Color.lerp(SnakeColors.snakeTail, SnakeColors.snakeBody, frac)!;

      canvas.drawRRect(rrect, Paint()..color = bodyColor);

      // Head details
      if (isHead) {
        _renderHead(canvas, p, rect);
      } else if (i < snake.length - 1) {
        // Body shine
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(rect.left + 2, rect.top + 2, rect.width - 4, rect.height * 0.4),
            Radius.circular(cs * 0.2),
          ),
          Paint()..color = Colors.white.withOpacity(0.08 * frac),
        );
      }
    }
  }

  void _renderHead(Canvas canvas, Point p, Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    // Eyes based on direction
    final eyeOffsets = _eyePositions(dir, cs * 0.22);
    for (final eo in eyeOffsets) {
      // White
      canvas.drawCircle(
        Offset(cx + eo.dx, cy + eo.dy),
        cs * 0.14,
        Paint()..color = Colors.white,
      );
      // Pupil
      canvas.drawCircle(
        Offset(cx + eo.dx + eo.dx * 0.1, cy + eo.dy + eo.dy * 0.1),
        cs * 0.07,
        Paint()..color = Colors.black,
      );
    }

    // Tongue
    final tongue = _tonguePoints(dir, cx, cy, cs);
    if (tongue != null) {
      final tp = Paint()
        ..color = SnakeColors.energy
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(tongue, tp);
    }
  }

  List<Offset> _eyePositions(SnakeDirection d, double r) {
    switch (d) {
      case SnakeDirection.up:    return [Offset(-r, -r * 0.8), Offset(r, -r * 0.8)];
      case SnakeDirection.down:  return [Offset(-r,  r * 0.8), Offset(r,  r * 0.8)];
      case SnakeDirection.left:  return [Offset(-r * 0.8, -r), Offset(-r * 0.8, r)];
      case SnakeDirection.right: return [Offset( r * 0.8, -r), Offset( r * 0.8, r)];
    }
  }

  Path? _tonguePoints(SnakeDirection d, double cx, double cy, double cs) {
    final len  = cs * 0.45;
    final fork = cs * 0.18;
    final path = Path();
    switch (d) {
      case SnakeDirection.up:
        path.moveTo(cx, cy - cs * 0.45);
        path.lineTo(cx, cy - cs * 0.45 - len);
        path.moveTo(cx, cy - cs * 0.45 - len);
        path.lineTo(cx - fork, cy - cs * 0.45 - len - fork);
        path.moveTo(cx, cy - cs * 0.45 - len);
        path.lineTo(cx + fork, cy - cs * 0.45 - len - fork);
        break;
      case SnakeDirection.down:
        path.moveTo(cx, cy + cs * 0.45);
        path.lineTo(cx, cy + cs * 0.45 + len);
        path.moveTo(cx, cy + cs * 0.45 + len);
        path.lineTo(cx - fork, cy + cs * 0.45 + len + fork);
        path.moveTo(cx, cy + cs * 0.45 + len);
        path.lineTo(cx + fork, cy + cs * 0.45 + len + fork);
        break;
      case SnakeDirection.left:
        path.moveTo(cx - cs * 0.45, cy);
        path.lineTo(cx - cs * 0.45 - len, cy);
        path.moveTo(cx - cs * 0.45 - len, cy);
        path.lineTo(cx - cs * 0.45 - len - fork, cy - fork);
        path.moveTo(cx - cs * 0.45 - len, cy);
        path.lineTo(cx - cs * 0.45 - len - fork, cy + fork);
        break;
      case SnakeDirection.right:
        path.moveTo(cx + cs * 0.45, cy);
        path.lineTo(cx + cs * 0.45 + len, cy);
        path.moveTo(cx + cs * 0.45 + len, cy);
        path.lineTo(cx + cs * 0.45 + len + fork, cy - fork);
        path.moveTo(cx + cs * 0.45 + len, cy);
        path.lineTo(cx + cs * 0.45 + len + fork, cy + fork);
        break;
    }
    return path;
  }
}

// ─────────────────────────────────────────────
//  FOOD RENDERER
// ─────────────────────────────────────────────
class _FoodRenderer extends Component {
  List<FoodItem> foods = [];
  final double   offsetX, offsetY, cs;
  double         _pulse = 0;

  _FoodRenderer({required this.offsetX, required this.offsetY, required this.cs});

  @override
  void update(double dt) {
    _pulse += dt * 4;
  }

  @override
  void render(Canvas canvas) {
    for (final food in foods) {
      final p     = food.position;
      final cx    = offsetX + p.x * cs + cs / 2;
      final cy    = offsetY + p.y * cs + cs / 2;
      final color = food.type.color;
      final glow  = 0.4 + sin(_pulse) * 0.25;

      // Expiring blink
      if (food.isExpiring && sin(_pulse * 3) > 0) continue;

      // Glow
      canvas.drawCircle(
        Offset(cx, cy),
        cs * 0.55,
        Paint()
          ..color = color.withOpacity(glow * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Body
      canvas.drawCircle(
        Offset(cx, cy),
        cs * 0.38,
        Paint()..color = color,
      );

      // Shine
      canvas.drawCircle(
        Offset(cx - cs * 0.1, cy - cs * 0.1),
        cs * 0.12,
        Paint()..color = Colors.white.withOpacity(0.4),
      );

      // Emoji label
      final tp = TextPaint(
        style: TextStyle(fontSize: cs * 0.45),
      );
      tp.render(canvas, food.type.emoji,
          Vector2(cx - cs * 0.22, cy - cs * 0.25));
    }
  }
}

// ─────────────────────────────────────────────
//  DEATH FLASH
// ─────────────────────────────────────────────
class _DeathFlash extends PositionComponent {
  final double screenW, screenH;
  double _opacity = 0.6;

  _DeathFlash({required this.screenW, required this.screenH});

  @override
  void update(double dt) {
    _opacity -= dt * 2.5;
    if (_opacity <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenW, screenH),
      Paint()..color = SnakeColors.energy.withOpacity(_opacity.clamp(0, 0.6)),
    );
  }
}
