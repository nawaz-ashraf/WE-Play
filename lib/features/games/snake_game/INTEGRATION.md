# Snake Game — Integration Guide

## Files Overview

| File | Purpose |
|------|---------|
| `snake_styles.dart` | Colors, constants, Direction, Point, FoodType, FoodItem models |
| `snake_engine.dart` | Pure Dart engine — movement, self-collision, food spawning, MoveResult |
| `snake_provider.dart` | Riverpod StateNotifier — game tick, direction queue, speed ramp, coin calc |
| `snake_game.dart` | FlameGame — grid/snake/food renderers, particle effects, death flash |
| `snake_screen.dart` | Flutter screen — HUD, D-pad, swipe input, speed badge, game over sheet |

---

## Step 1 — pubspec.yaml

```yaml
dependencies:
  flame: ^1.17.0
  flutter_animate: ^4.5.0
  flutter_riverpod: ^2.5.1
```

---

## Step 2 — Register route (router.dart)

```dart
import '../features/games/snake_game/snake_screen.dart';

GoRoute(
  path: '/lobby/game/snake_game',
  builder: (context, state) => const SnakeGameScreen(),
),
```

Remove the existing _ComingSoonScreen route for snake_game if present.

---

## Step 3 — Lobby card onTap

```dart
onTap: () => context.push('/lobby/game/snake_game'),
```

---

## Step 4 — Award coins on game over

In `snake_screen.dart`, inside `_showGameOver`:

```dart
final coinService = CoinService();
await coinService.awardCoins(state.coins);
await coinService.submitScore(
  gameId: 'snake_game',
  score: state.score,
  username: userModel.username,
  avatarUrl: userModel.avatarUrl,
);
```

---

## How It Works

### Movement System
- Snake stores a list of `Point` grid coordinates, head first
- Every `1/speed` seconds, the head moves one cell in current direction
- Body follows: insert new head, remove tail (unless food eaten = tail stays)
- Direction input queued as `nextDirection` — applied on next step to prevent 180° turns

### Grid
- 20 cols × 26 rows, cell size auto-fits to 92% of screen width
- Wrapping enabled — snake exits one edge and appears on the other
- Self collision = death (checks all body except tail which moves away)

### Food System
| Type | Score | Lifespan | Spawn Chance |
|------|-------|----------|-------------|
| 🍎 Apple | +10 | Never expires | ~72% |
| ⭐ Star | +25 | 6 seconds | ~20% |
| 💎 Gem | +50 | 4 seconds | ~8% |

- Always keeps 1 apple on board
- Expiring food blinks when < 2 seconds remain
- Expired food auto-removed each step

### Speed Ramp
- Starts at 6 cells/second
- +0.3 cells/second per food eaten
- Caps at 18 cells/second
- Speed badge shows: "slow" < 9, "fast" < 13, "MAX" ≥ 13

### Scoring
- Coins = floor(totalScore / 30)

---

## Customization

### Enable wall death (no wrapping)
```dart
// snake_engine.dart, in step():
// Replace wrap logic with:
if (newHead.x < 0 || newHead.x >= SnakeConst.cols ||
    newHead.y < 0 || newHead.y >= SnakeConst.rows) {
  return MoveResult.dead;
}
```

### Change grid size
```dart
// snake_styles.dart
static const int cols = 16;  // smaller = easier
static const int rows = 20;
```
