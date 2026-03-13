import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'beat_crash_components.dart';
import 'beat_crash_provider.dart';
import 'beat_crash_styles.dart';

// ─────────────────────────────────────────────
//  BEAT CRASH GAME  (FlameGame)
//
//  All notifier state changes are deferred via
//  Future() macrotasks so they never collide
//  with Flutter's build phase.
//  (Flame's GameWidget calls update() inside
//   build(), so addPostFrameCallback is not
//   sufficient.)
// ─────────────────────────────────────────────
class BeatCrashGame extends FlameGame with TapCallbacks {
  final BeatCrashNotifier notifier;

  BeatCrashGame({required this.notifier});

  // ── Sizing ────────────────────────────────
  late double _screenW;
  late double _screenH;
  late double _laneW;
  late double _targetY;    // centre of target zone
  late double _blockW;

  // ── BPM scheduling ────────────────────────
  final double _beatInterval = 60.0 / BeatConst.bpm; // seconds per beat
  double _beatTimer   = 0;
  int    _beatIndex   = 0;
  int    _totalBeats  = 0;
  late List<({int beat, int lane})> _schedule;

  // ── Active blocks ─────────────────────────
  final List<BeatBlock> _blocks = [];

  // ── Components ────────────────────────────
  late TargetZone _targetZone;
  late BeatBackground _bg;

  // ── State ─────────────────────────────────
  bool _started = false;
  double _localTimeLeft = BeatConst.sessionSeconds;

  /// Defers a notifier call to a macrotask outside
  /// the frame rendering pipeline.
  void _post(void Function() fn) {
    Future(fn);
  }

  // ─────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _screenW = size.x;
    _screenH = size.y;
    _laneW   = _screenW / BeatConst.lanes;
    _blockW  = _laneW * 0.78;
    _targetY = _screenH * (1 - BeatConst.targetZoneFromBottom);

    _totalBeats = (BeatConst.sessionSeconds / _beatInterval).ceil() + 4;
    _schedule   = BeatSchedule.generate(totalBeats: _totalBeats, seed: 42);

    // Background
    _bg = BeatBackground(screenW: _screenW, screenH: _screenH);
    add(_bg);

    // Target zone
    _targetZone = TargetZone(screenWidth: _screenW, y: _targetY);
    add(_targetZone);
  }

  void startGame() {
    _started       = true;
    _localTimeLeft = BeatConst.sessionSeconds;
    _beatTimer     = 0;
    _beatIndex     = 0;
    _blocks.clear();
    _post(() => notifier.startGame());
  }

  // ─────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!_started) return;

    _localTimeLeft -= dt;

    // Stop when time is up (tracked locally)
    if (_localTimeLeft <= 0) {
      _started = false;
      _post(() => notifier.endGame());
      return;
    }

    // Sync timer to provider after build phase
    _post(() => notifier.tick(dt));

    // ── BPM beat scheduler ─────────────────
    _beatTimer += dt;
    while (_beatTimer >= _beatInterval) {
      _beatTimer -= _beatInterval;
      _spawnBlocksForBeat(_beatIndex);
      _beatIndex++;
    }
  }

  void _spawnBlocksForBeat(int beat) {
    final events = _schedule.where((e) => e.beat == beat);
    for (final e in events) {
      _spawnBlock(e.lane);
    }
  }

  void _spawnBlock(int lane) {
    final x = _laneW * lane + _laneW / 2;
    final color = BeatColors.lanes[lane];

    final block = BeatBlock(
      lane:          lane,
      fallDuration:  BeatConst.fallDuration,
      targetY:       _targetY,
      startX:        x,
      blockW:        _blockW,
      startY:        -BeatConst.blockHeight,
      color:         color,
      onReachTarget: _autoMiss,
    );

    _blocks.add(block);
    add(block);
  }

  // ── Auto-miss when block exits window ─────
  void _autoMiss(BeatBlock block) {
    if (block.isHit) return;
    block.markHit();
    _blocks.remove(block);
    _post(() => notifier.recordHit(HitResult.miss));

    // Red flash
    add(ScreenFlash(
      screenW: _screenW,
      screenH: _screenH,
      color: BeatColors.miss,
    ));

    _spawnHitLabel(
      block.position.clone()..y = _targetY,
      HitResult.miss,
    );

    _targetZone.pulse(BeatColors.miss);
  }

  // ─────────────────────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    if (!_started) return;
    final tapX = event.localPosition.x;
    final lane  = (tapX / _laneW).floor().clamp(0, BeatConst.lanes - 1);
    _processTap(lane);
  }

  void _processTap(int lane) {
    // Find the closest block in this lane that is within hit window
    BeatBlock? best;
    double bestDist = double.infinity;

    for (final block in _blocks) {
      if (block.isHit || block.lane != lane) continue;
      final dist = (block.timePastTarget).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = block;
      }
    }

    if (best == null) {
      // Tap in empty lane → no penalty
      return;
    }

    final timeDelta = best.timePastTarget.abs();
    final HitResult result;
    if (timeDelta <= BeatConst.perfectWindow) {
      result = HitResult.perfect;
    } else if (timeDelta <= BeatConst.goodWindow) {
      result = HitResult.good;
    } else {
      result = HitResult.miss;
    }

    best.markHit();
    _blocks.remove(best);
    _post(() => notifier.recordHit(result));

    // Particles
    add(HitParticleBurst(
      position: Vector2(best.x, _targetY),
      color: result.color,
    ));

    // Hit label
    _spawnHitLabel(Vector2(best.x, _targetY - 30), result);

    // Target zone pulse
    _targetZone.pulse(result.color);

    // Miss flash
    if (result == HitResult.miss) {
      add(ScreenFlash(
        screenW: _screenW,
        screenH: _screenH,
        color: BeatColors.miss,
        opacity: 0.15,
      ));
    }
  }

  void _spawnHitLabel(Vector2 pos, HitResult result) {
    add(HitLabel(
      text:     result.label,
      color:    result.color,
      position: pos,
    ));
  }
}

