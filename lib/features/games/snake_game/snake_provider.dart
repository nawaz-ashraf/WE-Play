import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'snake_engine.dart';
import 'snake_styles.dart';
import '../../../core/services/score_persistence_service.dart';

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────
enum SnakeStatus { idle, playing, dead }

class SnakeState {
  final List<Point>       snake;
  final List<FoodItem>    foods;
  final SnakeDirection    direction;
  final SnakeDirection    nextDirection; // queued input
  final int               score;
  final int               coins;
  final int               bestScore;
  final double            speed;        // cells/second
  final SnakeStatus       status;
  final FoodType?         lastEaten;

  const SnakeState({
    this.snake         = const [],
    this.foods         = const [],
    this.direction     = SnakeDirection.up,
    this.nextDirection = SnakeDirection.up,
    this.score         = 0,
    this.coins         = 0,
    this.bestScore     = 0,
    this.speed         = SnakeConst.speedBase,
    this.status        = SnakeStatus.idle,
    this.lastEaten,
  });

  SnakeState copyWith({
    List<Point>?      snake,
    List<FoodItem>?   foods,
    SnakeDirection?   direction,
    SnakeDirection?   nextDirection,
    int?              score,
    int?              coins,
    int?              bestScore,
    double?           speed,
    SnakeStatus?      status,
    FoodType?         lastEaten,
  }) =>
      SnakeState(
        snake:         snake         ?? this.snake,
        foods:         foods         ?? this.foods,
        direction:     direction     ?? this.direction,
        nextDirection: nextDirection ?? this.nextDirection,
        score:         score         ?? this.score,
        coins:         coins         ?? this.coins,
        bestScore:     bestScore     ?? this.bestScore,
        speed:         speed         ?? this.speed,
        status:        status        ?? this.status,
        lastEaten:     lastEaten,
      );

  int get length => snake.length;
}

// ─────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────
class SnakeNotifier extends StateNotifier<SnakeState> {
  SnakeNotifier() : super(const SnakeState()) {
    _loadSavedBestScore();
  }

  final _scoreSvc = ScorePersistenceService();
  static const String _gameId = 'snake_game';

  final _engine = SnakeEngine();
  double _stepAccum = 0; // accumulates dt between steps

  void startGame() {
    final snake = _engine.initialSnake();
    final foods = <FoodItem>[_engine.spawnFood(snake, [])];
    _stepAccum  = 0;

    state = SnakeState(
      snake:         snake,
      foods:         foods,
      direction:     SnakeDirection.up,
      nextDirection: SnakeDirection.up,
      status:        SnakeStatus.playing,
      bestScore:     state.bestScore,
      speed:         SnakeConst.speedBase,
    );
  }

  // ── Called every frame from game loop ─────
  void tick(double dt) {
    if (state.status != SnakeStatus.playing) return;

    _stepAccum += dt;
    final stepInterval = 1.0 / state.speed;

    if (_stepAccum < stepInterval) return;
    _stepAccum -= stepInterval;

    _doStep(dt);
  }

  void _doStep(double dt) {
    final snake  = List<Point>.from(state.snake);
    final foods  = state.foods.map((f) => FoodItem(
      position: f.position,
      type:     f.type,
      lifespan: f.lifespan,
    )).toList();

    // Apply queued direction
    final dir    = state.nextDirection;

    final result = _engine.step(
      snake:     snake,
      direction: dir,
      foods:     foods,
      dt:        dt,
    );

    if (result.isDead) {
      state = state.copyWith(
        snake:  snake,
        status: SnakeStatus.dead,
      );
      return;
    }

    int   newScore = state.score;
    int   newCoins = state.coins;
    double newSpeed = state.speed;

    if (result.ateFood) {
      final pts   = result.eaten!.score;
      newScore   += pts;
      newCoins    = newScore ~/ SnakeConst.coinEvery;
      newSpeed    = (state.speed + SnakeConst.speedInc)
          .clamp(0.0, SnakeConst.speedMax);

      // Always keep one apple on board
      if (!foods.any((f) => f.type == FoodType.apple)) {
        foods.add(_engine.spawnFood(snake, foods));
      }
      // Chance to spawn bonus food
      if (foods.length < 2) {
        foods.add(_engine.spawnFood(snake, foods));
      }
    }

    final newBest = newScore > state.bestScore ? newScore : state.bestScore;

    if (newScore > state.bestScore) {
      _scoreSvc.saveBestScore(_gameId, newScore);
    }

    state = state.copyWith(
      snake:         snake,
      foods:         foods,
      direction:     dir,
      score:         newScore,
      coins:         newCoins,
      bestScore:     newBest,
      speed:         newSpeed,
      lastEaten:     result.eaten,
    );
  }

  // ── Direction input ───────────────────────
  void setDirection(SnakeDirection d) {
    if (state.status != SnakeStatus.playing) return;
    // Prevent reversing into self
    if (d.isOpposite(state.direction)) return;
    state = state.copyWith(nextDirection: d);
  }

  Future<void> _loadSavedBestScore() async {
    final saved = await _scoreSvc.loadBestScore(_gameId);
    if (saved > state.bestScore && mounted) {
      state = state.copyWith(bestScore: saved);
    }
  }
}

// ─────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────
final snakeProvider =
    StateNotifierProvider<SnakeNotifier, SnakeState>(
  (ref) => SnakeNotifier(),
);
