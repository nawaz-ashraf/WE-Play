# Flick Royale — Integration Guide

## Files Overview

| File | Purpose |
|------|---------|
| `flick_styles.dart` | Colors, constants, PuckOwner enum, RoundWinner enum, AI difficulty config |
| `flick_provider.dart` | Riverpod StateNotifier — rounds, puck counts, score, coins, AI difficulty |
| `flick_components.dart` | Flame/Forge2D: PuckBody, ArenaWalls, ArenaRenderer, AimLine, KnockOffBurst, FlickScreenFlash, FlickBackground |
| `flick_ai.dart` | AiController — difficulty-scaled firing with aim noise and delay |
| `flick_game.dart` | Forge2DGame — puck spawning, drag-to-flick, knock-off detection, AI integration |
| `flick_screen.dart` | Flutter screen — HUD, round tracker, puck indicators, round/match over sheets |

---

## Step 1 — pubspec.yaml

```yaml
dependencies:
  flame: ^1.17.0
  flame_forge2d: ^0.18.0
  flutter_animate: ^4.5.0
  flutter_riverpod: ^2.5.1
```

---

## Step 2 — Register route (router.dart)

```dart
import '../features/games/flick_royale/flick_screen.dart';

GoRoute(
  path: '/lobby/game/flick_royale',
  builder: (context, state) => const FlickRoyaleScreen(),
),
```

---

## Step 3 — Lobby card onTap

```dart
onTap: () => context.push('/lobby/game/flick_royale'),
```

---

## Step 4 — Award coins on match over

In `flick_screen.dart`, inside `_showMatchOver`:

```dart
final coinService = CoinService();
await coinService.awardCoins(state.coins);
await coinService.submitScore(
  gameId: 'flick_royale',
  score: state.score,
  username: userModel.username,
  avatarUrl: userModel.avatarUrl,
);
```

---

## How Physics Works

| Property | Value | Effect |
|----------|-------|--------|
| Gravity | 0 (zero) | Top-down view — no falling |
| Restitution | 0.82 | High bounce off walls |
| Friction | 0.08 | Minimal surface friction |
| Linear damping | 0.55 | Pucks slow down naturally |
| Max impulse | 14 m/s | Caps flick power |
| worldScale | 40 px/m | 40px = 1 metre |

---

## How Drag-to-Flick Works

1. `onDragStart` — finds closest player puck within 2.5× puck radius
2. `onDragUpdate` — updates AimLine endpoint
3. `onDragEnd` — calculates delta from start to end, **reverses it** (flick = opposite to drag direction), clamps to 120px = max power, applies as linear impulse

---

## How AI Works

| Difficulty | Accuracy | Speed | Delay |
|-----------|----------|-------|-------|
| 0 (easiest) | 55% | 60% | 1.2s |
| 1 | 65% | 70% | 0.95s |
| 2 | 75% | 80% | 0.75s |
| 3 | 85% | 90% | 0.55s |
| 4 (hardest) | 95% | 100% | 0.35s |

Difficulty level = player's current win streak (capped at 4).
AI picks a target (lowest-velocity player puck), adds angular noise based on accuracy, fires with speed × speedMult.

---

## How Knock-off Works

Every frame, each puck's world-pixel position is checked:
- **Player puck**: knocked off if Y < centreY - 10 (crossed into AI zone) OR outside arena bounds
- **AI puck**: knocked off if Y > centreY + 10 (crossed into player zone) OR outside arena bounds
- On knock-off: particle burst + screen flash + notifier update

---

## Scoring

- Each AI puck knocked off = +10 points
- Round win = +3 coins
- Match win = +10 coins bonus
- All stored in Firestore via CoinService
