# Flappy Bird — Integration Guide

## Files Overview

| File | Purpose |
|------|---------|
| `flappy_styles.dart` | Colors, constants, StarData struct |
| `flappy_provider.dart` | Riverpod StateNotifier — score, coins, best, speed ramp |
| `flappy_components.dart` | Flame components: Bird, PipePair, Ground, FlappyBackground, ScorePopup, DeathBurst, FlappyFlash |
| `flappy_game.dart` | FlameGame — pipe spawning, gravity, collision, scoring |
| `flappy_screen.dart` | Flutter screen — score HUD, start overlay, game over sheet |

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
import '../features/games/flappy_bird/flappy_screen.dart';

GoRoute(
  path: '/lobby/game/flappy_bird',
  builder: (context, state) => const FlappyBirdScreen(),
),
```

---

## Step 3 — Lobby card onTap

```dart
onTap: () => context.push('/lobby/game/flappy_bird'),
```

---

## Step 4 — Award coins on game over

In `flappy_screen.dart`, inside `_showGameOver`:

```dart
final coinService = CoinService();
await coinService.awardCoins(state.coins);
await coinService.submitScore(
  gameId: 'flappy_bird',
  score: state.score,
  username: userModel.username,
  avatarUrl: userModel.avatarUrl,
);
```

---

## How It Works

### Physics (manual, no Forge2D needed)
- `velocity` starts at 0, gravity adds 1100 px/s² every frame
- Tap = velocity snaps to -520 px/s (upward)
- Bird angle = velocity / 800 (tilts nose up/down naturally)

### Difficulty Ramp
- Pipe speed starts at 180 px/s, +4 px/s per pipe scored, caps at 380 px/s
- Gap starts at 180px, shrinks 8px every 10 pipes scored, minimum 130px
- Pipes spawn at interval = pipeSpacing / currentSpeed (auto-adjusts to speed)

### Scoring
- +1 score when bird's X passes pipe's right edge
- +1 coin every 5 pipes scored
- Best score persists across sessions via Riverpod state

---

## Customization

### Make it harder from the start
```dart
// flappy_styles.dart
static const double pipeSpeedBase  = 220.0;  // faster start
static const double pipeGap        = 160.0;  // smaller gap
static const double flapImpulse    = -480.0; // weaker flap
```

### Add multiple birds (multiplayer locally)
- Spawn 2 Bird instances at different Y positions
- Track both independently
- Game ends when both are dead
