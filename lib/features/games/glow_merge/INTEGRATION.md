# Glow Merge — Integration Guide

## Files Overview

| File | Purpose |
|------|---------|
| `glow_merge_logic.dart` | Pure Dart game engine. No Flutter deps. Handles swipe logic, merges, coin calc. |
| `glow_merge_provider.dart` | Riverpod StateNotifier. Holds game state. |
| `glow_merge_styles.dart` | Color constants + blob style map (value → neon color). |
| `glow_merge_screen.dart` | Full game UI: grid, swipe detector, score HUD, game over sheet. |
| `coin_service.dart` | Firestore coin + leaderboard integration. |

---

## Step 1 — Add to pubspec.yaml

```yaml
dependencies:
  flutter_animate: ^4.5.0
  flutter_riverpod: ^2.5.1
  cloud_firestore: ^4.15.0
  firebase_auth: ^4.17.0

flutter:
  fonts:
    - family: Orbitron
      fonts:
        - asset: assets/fonts/Orbitron-Regular.ttf
          weight: 400
        - asset: assets/fonts/Orbitron-Bold.ttf
          weight: 700
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Regular.ttf
          weight: 400
        - asset: assets/fonts/Nunito-SemiBold.ttf
          weight: 600
```

> Download Orbitron + Nunito from fonts.google.com and place in `assets/fonts/`.

---

## Step 2 — Route registration (go_router)

```dart
// In router.dart
GoRoute(
  path: '/lobby/game/glow_merge',
  builder: (ctx, state) => const GlowMergeScreen(),
),
```

---

## Step 3 — Lobby card tap

```dart
// In LobbyScreen game card onTap:
onTap: () => context.push('/lobby/game/glow_merge'),
```

---

## Step 4 — Award coins after session ends

In `GlowMergeNotifier.swipe()`, when `isOver == true`:

```dart
// After state update:
final coinService = CoinService();
await coinService.awardCoins(state.coins);
await coinService.submitScore(
  gameId: 'glow_merge',
  score: newScore,
  username: userModel.username,
  avatarUrl: userModel.avatarUrl,
);
```

Or wire it up via a Riverpod ref inside the notifier constructor.

---

## Step 5 — Wrap app in ProviderScope (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: WePlayApp()));
}
```

---

## Game Logic Notes

- **Values are stored as exponents**: blob value `1` = tile showing `2` (2^1), value `2` = `4` (2^2), etc. This prevents integer overflow at high merges.
- **Coin rule**: every merge producing a blob with `value >= 5` (tile showing 32+) awards 1 coin.
- **Game over**: triggered when no empty cells AND no adjacent equal blobs remain.
- **Grid size**: constant `GlowMergeEngine.size = 4`. Change to 5 for a harder mode (unlock with coins).

---

## Customization

### Change grid size to 5×5
```dart
// glow_merge_logic.dart
static const int size = 5;  // change from 4

// glow_merge_screen.dart — GridView crossAxisCount:
crossAxisCount: GlowMergeEngine.size,  // already dynamic
```

### Add power-up: "shuffle board"
```dart
// In GlowMergeNotifier:
void shuffleBoard() {
  final allBlobs = state.grid.expand((r) => r).whereType<Blob>().toList();
  allBlobs.shuffle();
  final newGrid = _engine.newGame(); // blank
  int i = 0;
  for (int r = 0; r < GlowMergeEngine.size; r++) {
    for (int c = 0; c < GlowMergeEngine.size; c++) {
      if (i < allBlobs.length) newGrid[r][c] = allBlobs[i++];
    }
  }
  state = state.copyWith(grid: newGrid);
}
```

### Add rewarded ad for +5 moves
```dart
// On score screen, show rewarded ad button:
// After ad completes → call adService.showRewardedAd()
// On reward → show "keep merging!" + don't end game for 5 more moves
```
