import 'dart:math';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'flick_components.dart';
import 'flick_styles.dart';

// ─────────────────────────────────────────────
//  AI CONTROLLER
//  Runs on a delay timer. Picks a target puck
//  (player's), aims at it with accuracy noise,
//  fires from one of its own pucks.
// ─────────────────────────────────────────────
class AiController {
  final int difficulty; // 0–4
  final _rng = Random();

  double _actionTimer;   // countdown to next AI action
  bool   _fired = false;

  AiController({required this.difficulty})
      : _actionTimer = FlickConst.aiDelayRange[
            difficulty.clamp(0, FlickConst.aiDelayRange.length - 1)];

  void reset() {
    _actionTimer = _delay;
    _fired = false;
  }

  double get _accuracy =>
      FlickConst.aiAccuracy[difficulty.clamp(0, FlickConst.aiAccuracy.length - 1)];

  double get _speedMult =>
      FlickConst.aiSpeedMult[difficulty.clamp(0, FlickConst.aiSpeedMult.length - 1)];

  double get _delay =>
      FlickConst.aiDelayRange[difficulty.clamp(0, FlickConst.aiDelayRange.length - 1)];

  /// Call every frame. Returns the impulse to apply if it's time to fire,
  /// or null otherwise.
  ///
  /// [aiPucks]     – list of AI's own pucks still on arena
  /// [playerPucks] – list of player's pucks (targets)
  /// [centreY]     – world-px Y of the centre line (AI stays above this)
  AiShot? update(
    double dt,
    List<PuckBody> aiPucks,
    List<PuckBody> playerPucks,
  ) {
    if (aiPucks.isEmpty || playerPucks.isEmpty) return null;

    _actionTimer -= dt;
    if (_actionTimer > 0) return null;

    _actionTimer = _delay + _rng.nextDouble() * 0.4;

    // Pick source puck (random AI puck)
    final src = aiPucks[_rng.nextInt(aiPucks.length)];

    // Pick target puck (player puck with least velocity = easiest to hit)
    playerPucks.sort((a, b) =>
        a.body.linearVelocity.length.compareTo(b.body.linearVelocity.length));
    final target = playerPucks.first;

    // Ideal direction
    final srcPx  = src.worldPx;
    final tgtPx  = target.worldPx;
    final ideal  = (tgtPx - srcPx).normalized();

    // Add noise based on accuracy (lower accuracy = more noise)
    final noiseAngle = (_rng.nextDouble() - 0.5) * 2 * (1 - _accuracy) * pi * 0.5;
    final cos_ = cos(noiseAngle);
    final sin_ = sin(noiseAngle);
    final noisy = Vector2(
      ideal.x * cos_ - ideal.y * sin_,
      ideal.x * sin_ + ideal.y * cos_,
    );

    // Speed
    final speed = FlickConst.maxFlickImpulse * _speedMult *
        (0.6 + _rng.nextDouble() * 0.4);

    return AiShot(puck: src, impulse: noisy * speed);
  }
}

class AiShot {
  final PuckBody puck;
  final Vector2  impulse;
  const AiShot({required this.puck, required this.impulse});
}
