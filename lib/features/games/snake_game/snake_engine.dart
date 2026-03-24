import 'dart:math';
import 'snake_styles.dart';

// ─────────────────────────────────────────────
//  SNAKE ENGINE  — pure Dart, no Flutter deps
// ─────────────────────────────────────────────
class SnakeEngine {
  final _rng = Random();

  // ── Initial state ─────────────────────────
  List<Point> initialSnake() => [
        const Point(10, 13),
        const Point(10, 14),
        const Point(10, 15),
      ];

  // ── Move snake one step ───────────────────
  /// Returns MoveResult — what happened this step.
  MoveResult step({
    required List<Point>  snake,
    required SnakeDirection direction,
    required List<FoodItem> foods,
    required double dt,
  }) {
    final head    = snake.first;
    final delta   = direction.delta;
    final newHead = Point(
      (head.x + delta.x + SnakeConst.cols) % SnakeConst.cols,
      (head.y + delta.y + SnakeConst.rows) % SnakeConst.rows,
    );

    // Wall collision (wrap = false → death)
    // We use WRAP mode here — change to death mode below if preferred:
    // if (newHead.x < 0 || newHead.x >= SnakeConst.cols ||
    //     newHead.y < 0 || newHead.y >= SnakeConst.rows) {
    //   return MoveResult.dead;
    // }

    // Self collision (skip the tail — it will move away)
    final bodyWithoutTail = snake.sublist(0, snake.length - 1);
    if (bodyWithoutTail.contains(newHead)) {
      return MoveResult.dead;
    }

    // Check food
    final eatenIndex = foods.indexWhere((f) => f.position == newHead);
    FoodType? eaten;
    if (eatenIndex >= 0) {
      eaten = foods[eatenIndex].type;
      foods.removeAt(eatenIndex);
    }

    // Grow or move
    snake.insert(0, newHead);
    if (eaten == null) {
      snake.removeLast(); // no food = just move
    }
    // If eaten = food, keep tail (snake grows)

    // Tick food lifespans
    for (final f in foods) {
      if (f.lifespan > 0) {
        f.lifespan = (f.lifespan - dt).clamp(0, double.infinity);
      }
    }
    foods.removeWhere((f) => f.lifespan == 0);

    if (eaten != null) return MoveResult.ate(eaten);
    return MoveResult.moved;
  }

  // ── Spawn food ────────────────────────────
  FoodItem spawnFood(List<Point> snake, List<FoodItem> existing) {
    // Find empty cell
    final occupied = {
      ...snake,
      ...existing.map((f) => f.position),
    };
    final empty = <Point>[];
    for (int x = 0; x < SnakeConst.cols; x++) {
      for (int y = 0; y < SnakeConst.rows; y++) {
        final p = Point(x, y);
        if (!occupied.contains(p)) empty.add(p);
      }
    }
    if (empty.isEmpty) return FoodItem(
      position: const Point(0, 0),
      type: FoodType.apple,
      lifespan: -1,
    );

    final pos  = empty[_rng.nextInt(empty.length)];
    final roll = _rng.nextInt(100);
    final type = roll < SnakeConst.gemChance
        ? FoodType.gem
        : roll < SnakeConst.starChance
            ? FoodType.star
            : FoodType.apple;

    final lifespan = type == FoodType.gem
        ? SnakeConst.gemLifespan
        : type == FoodType.star
            ? SnakeConst.starLifespan
            : -1.0; // apples never expire

    return FoodItem(position: pos, type: type, lifespan: lifespan);
  }
}

// ─────────────────────────────────────────────
//  MOVE RESULT
// ─────────────────────────────────────────────
class MoveResult {
  final bool      isDead;
  final FoodType? eaten;

  const MoveResult._({this.isDead = false, this.eaten});

  static const MoveResult moved = MoveResult._();
  static const MoveResult dead  = MoveResult._(isDead: true);
  static MoveResult ate(FoodType t) => MoveResult._(eaten: t);

  bool get ateFood => eaten != null;
}
