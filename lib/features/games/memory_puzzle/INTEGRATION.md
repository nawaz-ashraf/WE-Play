# Memory Puzzle — Integration Guide

## Files Overview

| File | Purpose |
|------|---------|
| `memory_styles.dart` | Colors, constants, difficulty config, emoji pool, MemoryCard model |
| `memory_engine.dart` | Pure Dart game logic — deck generation, flip logic, match detection |
| `memory_provider.dart` | Riverpod StateNotifier — cards, timer, score, coin calculation |
| `memory_widgets.dart` | Card widget with 3D flip animation, shake on mismatch, progress bar, timer ring |
| `memory_screen.dart` | Full game screen — grid, HUD, difficulty picker, game over sheet |

---

## Step 1 — pubspec.yaml

```yaml
dependencies:
  flutter_animate: ^4.5.0
  flutter_riverpod: ^2.5.1
  cloud_firestore: ^4.15.0
  firebase_auth: ^4.17.0
```

No Flame needed — this is a pure Flutter widget game.

---

## Step 2 — Register route (router.dart)

```dart
import '../features/games/memory_puzzle/memory_screen.dart';

GoRoute(
  path: '/lobby/game/memory_puzzle',
  builder: (context, state) => const MemoryPuzzleScreen(),
),
```

---

## Step 3 — Lobby card onTap

```dart
onTap: () => context.push('/lobby/game/memory_puzzle'),
```

---

## Step 4 — Award coins on complete

In `memory_screen.dart`, inside `_showComplete`:

```dart
final coinService = CoinService();
await coinService.awardCoins(state.coins);
await coinService.submitScore(
  gameId: 'memory_puzzle',
  score: state.score,
  username: userModel.username,
  avatarUrl: userModel.avatarUrl,
);
```

---

## How It Works

### Difficulty Levels
| Difficulty | Grid | Pairs | Time |
|-----------|------|-------|------|
| Easy | 4×3 | 6 | 60s |
| Medium | 4×4 | 8 | 90s |
| Hard | 4×5 | 10 | 120s |

### Card Flip Logic
- Tap 1st card → flip face up, wait
- Tap 2nd card → check pairId match
  - Match → both stay face up, marked as matched, +100 + time bonus score
  - No match → both flip back after 0.9 seconds, shake animation plays
- Locked (`isFlipping = true`) during flip-back delay to prevent cheating

### Scoring
- Per pair matched: 100 points + floor(timeLeft / 10) time bonus
- Completing all pairs with time left: +5 bonus coins
- Best score persists across sessions

### 3D Flip Animation
- Uses `AnimationController` + `Matrix4.rotateY`
- Front/back switch at pi/2 midpoint
- `didUpdateWidget` triggers forward/reverse based on `isFaceUp` state

---

## Customization

### Add more emojis
```dart
// memory_styles.dart — extend kCardEmojis list
const List<String> kCardEmojis = [
  // ... existing emojis ...
  '🦊', '🐼', '🦋', '🌺', '🍕',
];
```

### Add an "extreme" difficulty
```dart
// memory_styles.dart
enum MemoryDifficulty { easy, medium, hard, extreme }

// Add to gridSizes:
MemoryDifficulty.extreme: (cols: 5, rows: 6), // 30 cards = 15 pairs

// Add to timeLimits:
MemoryDifficulty.extreme: 150,
```
