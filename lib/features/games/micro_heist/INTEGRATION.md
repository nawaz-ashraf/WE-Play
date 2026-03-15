# Micro Heist — Integration Guide

## Files Overview

| File | Purpose |
|------|---------|
| `heist_styles.dart` | Colors, constants, CellType, LaserDef, LevelDef, 5 pre-built levels, GridParser |
| `heist_provider.dart` | Riverpod StateNotifier — level, score, coins, timer, loot, status |
| `heist_components.dart` | Flame components: GridMap, ThiefSprite, LootItem, ExitDoor, LaserBeam, BustedFlash, HeistBackground |
| `heist_game.dart` | FlameGame — grid movement, laser collision, level loading, tap + keyboard input |
| `heist_screen.dart` | Flutter screen — HUD, D-pad, swipe input, level banner, game over sheet |

---

## Step 1 — pubspec.yaml

```yaml
dependencies:
  flame: ^1.17.0
  flutter_animate: ^4.5.0
  flutter_riverpod: ^2.5.1
```

Run `flutter pub get`.

---

## Step 2 — Register route (router.dart)

```dart
import '../features/games/micro_heist/heist_screen.dart';

GoRoute(
  path: '/lobby/game/micro_heist',
  builder: (context, state) => const MicroHeistScreen(),
),
```

---

## Step 3 — Lobby card onTap

```dart
onTap: () => context.push('/lobby/game/micro_heist'),
```

---

## Step 4 — Award coins on game over

In `heist_screen.dart`, inside `_showGameOver` and `_showGameComplete`:

```dart
final coinService = CoinService();
await coinService.awardCoins(state.coins);
await coinService.submitScore(
  gameId: 'micro_heist',
  score: state.score,
  username: userModel.username,
  avatarUrl: userModel.avatarUrl,
);
```

Import from:
```dart
import '../../glow_merge/coin_service.dart';
```

---

## How It Works

### Grid System
- 9 columns × 12 rows, each cell = 38px
- Grid is centred on screen automatically
- Cell types: floor, wall, loot ($), exit (E), thief start (T)

### Movement
- Tap: tap anywhere → direction determined by which side of thief you tap
- D-Pad: 4 on-screen buttons at the bottom
- Swipe: full-screen swipe gesture also works
- Keyboard: arrow keys work on tablets/desktop

### Laser Collision
- Each laser has a `worldRect` (Rect in screen coordinates)
- Every frame, thief's world rect is checked against all laser rects
- Touch = `_triggerBusted()` → red flash + game over

### Level Progression
- 5 levels with increasing laser count and speed
- Laser speeds: 1.2 → 1.6 → 2.1 → 2.7 → 3.4 cells/second
- Level complete = grab loot ($) then reach exit (E)
- Time bonus = floor(timeLeft × 0.15) coins per level
- Auto-advances to next level after 1.2 second banner

---

## Adding More Levels

Add to `kLevels` list in `heist_styles.dart`:

```dart
LevelDef(
  title: 'The Museum',
  timeLimitSec: 18,
  grid: [
    '#########',
    '#T      #',
    '# ##### #',
    '#       #',
    '# ## ## #',
    '#   \$   #',
    '# ## ## #',
    '#       #',
    '# ##### #',
    '#      E#',
    '#       #',
    '#########',
  ],
  lasers: [
    LaserDef(axis: LaserAxis.horizontal, fixedIndex: 3, sweepStart: 1, sweepEnd: 7, phase: 0.0),
    LaserDef(axis: LaserAxis.vertical,   fixedIndex: 4, sweepStart: 3, sweepEnd: 9, phase: 0.5),
    LaserDef(axis: LaserAxis.horizontal, fixedIndex: 7, sweepStart: 1, sweepEnd: 7, phase: 0.3),
  ],
),
```

Grid rules:
- Must be exactly 12 rows, each row exactly 9 chars
- `#` = wall, ` ` = floor, `T` = thief start, `\$` = loot, `E` = exit
- Every level must have exactly 1 T, 1 \$, 1 E
- Ensure a valid path exists from T → \$ → E
