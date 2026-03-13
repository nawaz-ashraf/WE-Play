# Beat Crash — Integration Guide

## Files Overview

| File | Purpose |
|------|---------|
| `beat_crash_styles.dart` | Colors, constants, BPM config, HitResult enum, BeatSchedule generator |
| `beat_crash_provider.dart` | Riverpod StateNotifier — score, combo, timer, multiplier |
| `beat_crash_components.dart` | All Flame components: BeatBlock, TargetZone, HitParticleBurst, HitLabel, BeatBackground, ScreenFlash |
| `beat_crash_game.dart` | FlameGame — BPM scheduler, tap detection, hit window logic |
| `beat_crash_screen.dart` | Flutter screen wrapper — HUD overlay, combo bar, timer ring, game over sheet |

---

## Step 1 — Add Flame to pubspec.yaml

```yaml
dependencies:
  flame: ^1.17.0
  flutter_animate: ^4.5.0
  flutter_riverpod: ^2.5.1
```

Run `flutter pub get`.

---

## Step 2 — Register the route (router.dart)

```dart
import '../features/games/beat_crash/beat_crash_screen.dart';

GoRoute(
  path: '/lobby/game/beat_crash',
  builder: (context, state) => const BeatCrashScreen(),
),
```

---

## Step 3 — Lobby card onTap

```dart
onTap: () => context.push('/lobby/game/beat_crash'),
```

---

## Step 4 — Award coins on game over

In `beat_crash_screen.dart`, inside `_showGameOver`, after the sheet is shown:

```dart
// Award coins to Firestore
final coinService = CoinService();
await coinService.awardCoins(state.coins);
await coinService.submitScore(
  gameId: 'beat_crash',
  score: state.score,
  username: userModel.username,
  avatarUrl: userModel.avatarUrl,
);
```

---

## How BPM Sync Works

- `_beatInterval = 60 / 120 = 0.5 seconds` per beat at 120 BPM
- `BeatSchedule.generate()` pre-generates a list of `(beat, lane)` pairs for the full 30-second session
- Every `update(dt)`, `_beatTimer` accumulates. When it exceeds `_beatInterval`, a beat fires and blocks spawn for that beat number
- Each `BeatBlock` starts at `y = -blockHeight` and moves to `targetY` over `fallDuration = 1.2 seconds`
- Hit windows: `±0.10s` = PERFECT, `±0.20s` = GOOD, beyond = auto-MISS

---

## Customization

### Change BPM
```dart
// beat_crash_styles.dart
static const int bpm = 140;  // faster = harder
```

### Change session length
```dart
static const double sessionSeconds = 40.0;
```

### Add audio (audioplayers)
```dart
// In BeatCrashGame.onLoad():
final player = AudioPlayer();
await player.setSource(AssetSource('audio/beat_crash_track.mp3'));
await player.resume();

// On perfect hit:
await AudioPlayer().play(AssetSource('audio/hit_perfect.mp3'));
```

Add to pubspec.yaml:
```yaml
audioplayers: ^6.0.0

flutter:
  assets:
    - assets/audio/
```

### Make BPM increase over time (difficulty ramp)
```dart
// In BeatCrashGame.update():
final elapsed = BeatConst.sessionSeconds - notifier.state.timeLeft;
final currentBpm = BeatConst.bpm + (elapsed * 0.5).toInt(); // +0.5 BPM per second
_beatInterval = 60.0 / currentBpm;
```

---

## Combo Multiplier Table

| Combo | Multiplier |
|-------|-----------|
| 0–4   | 1×        |
| 5–9   | 2×        |
| 10–19 | 3×        |
| 20–29 | 5×        |
| 30–49 | 8×        |
| 50+   | 10×       |

---

## Notes

- `BeatBlock.timePastTarget` is negative before the block reaches target, positive after.
  Hit detection uses `abs()` so both early and late taps are judged fairly.
- `onReachTarget` callback fires when a block exits the good window — this auto-registers a MISS.
- The Flame canvas is full-screen. The Flutter HUD (score, timer, combo bar) is layered on top using a `Stack`.
- `GameWidget(game: _game)` must be rebuilt with a new game instance on restart — this is handled in `_showGameOver → onAgain`.
