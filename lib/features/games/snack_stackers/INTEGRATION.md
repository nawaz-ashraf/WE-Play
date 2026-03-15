# Snack Stackers — Integration Guide

## Files Overview

| File | Purpose |
|------|---------|
| `snack_styles.dart` | Colors, constants, 7 food item configs with physics params |
| `snack_provider.dart` | Riverpod StateNotifier — height, coins, timer, wobble state |
| `snack_components.dart` | Flame/Forge2D components: FoodBody, StackPlatform, Dropper, HeightMeter, StackBackground, WobbleEffect |
| `snack_game.dart` | Forge2DGame — physics world, tap-to-drop, height tracking, fall detection |
| `snack_screen.dart` | Flutter screen — HUD, next item preview, wobble warning, game over sheet |

---

## Step 1 — Add flame_forge2d to pubspec.yaml

```yaml
dependencies:
  flame: ^1.17.0
  flame_forge2d: ^0.18.0
  flutter_animate: ^4.5.0
  flutter_riverpod: ^2.5.1
```

Run `flutter pub get`.

---

## Step 2 — Register route (router.dart)

```dart
import '../features/games/snack_stackers/snack_screen.dart';

GoRoute(
  path: '/lobby/game/snack_stackers',
  builder: (context, state) => const SnackStackersScreen(),
),
```

---

## Step 3 — Lobby card onTap

```dart
onTap: () => context.push('/lobby/game/snack_stackers'),
```

---

## Step 4 — Award coins on game over

In `snack_screen.dart`, inside `_showGameOver`:

```dart
final coinService = CoinService();
await coinService.awardCoins(state.coins);
await coinService.submitScore(
  gameId: 'snack_stackers',
  score: state.score,
  username: userModel.username,
  avatarUrl: userModel.avatarUrl,
);
```

---

## Physics Explained

| Property | Value | Effect |
|----------|-------|--------|
| Gravity | 18 m/s² | Heavier than Earth — satisfying drops |
| worldScale | 40 px/m | 1 metre = 40 pixels |
| Burger density | 1.2 | Heavy — settles fast |
| Donut density | 0.6 | Light — bounces more |
| Donut restitution | 0.35 | Bounciest item |
| Sandwich friction | 0.85 | Grippiest item |

---

## How Height Tracking Works

- Platform is placed at `screenH * 0.86` from top
- Every frame, the game scans all FoodBody objects
- Finds the topmost body Y position
- `heightPx = platformY - topBodyY`
- Height is passed to `notifier.updateHeight()` every frame
- Score = height in pixels, coins = `floor(height * 0.02)`

---

## How Fall Detection Works

- A body is "settled" when its linear velocity < 0.05 m/s for 0.5 seconds
- If a settled body Y > platformY + 100px → it fell off → `notifier.towerFell()`
- Tower fell = game over immediately

---

## Customization

### Add a new food item
```dart
// In snack_styles.dart, add to kFoodItems:
FoodConfig(
  emoji: '🍦', name: 'IceCream',
  width: 44, height: 58,
  density: 0.5, restitution: 0.40, friction: 0.35,
  color: Color(0xFF1A0040), border: Color(0xFFE040FB),
),
```

### Change dropper speed
```dart
// snack_styles.dart
static const double dropperSpeed = 160.0; // faster = harder
```

### Make items get heavier over time
```dart
// In snack_game.dart _dropItem():
final density = config.density + (state.itemsDropped * 0.05);
// Apply as custom density in FoodBody
```
