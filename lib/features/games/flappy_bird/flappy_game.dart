import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'flappy_components.dart';
import 'flappy_provider.dart';
import 'flappy_styles.dart';

// ─────────────────────────────────────────────
//  FLAPPY BIRD GAME  (FlameGame)
// ─────────────────────────────────────────────
class FlappyGame extends FlameGame with TapCallbacks {
  final FlappyNotifier notifier;

  FlappyGame({required this.notifier});

  // ── Layout ────────────────────────────────
  late double _screenW, _screenH;

  // ── Components ────────────────────────────
  late FlappyBackground _bg;
  late Ground           _ground;
  late Bird             _bird;
  final List<PipePair>  _pipes = [];

  // ── Pipe spawning ─────────────────────────
  double _pipeTimer    = 0;
  double _pipeInterval = 0; // seconds between pipes
  final _rng           = Random();

  bool _started = false;
  bool _dead    = false;

  // ─────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _screenW = size.x;
    _screenH = size.y;

    _bg = FlappyBackground(screenW: _screenW, screenH: _screenH);
    add(_bg);

    _ground = Ground(screenW: _screenW, screenH: _screenH);
    add(_ground);
  }

  void startGame() {
    _started = true;
    _dead    = false;
    _pipes.clear();
    removeWhere((c) => c is PipePair || c is Bird || c is DeathBurst || c is FlappyFlash);

    notifier.startGame();

    // Bird starts at 40% height
    _bird = Bird(x: _screenW * FlappyConst.birdX, y: _screenH * 0.4);
    _bird.flap(); // Initial flap to give the player time to react
    add(_bird);

    _pipeTimer    = 0;
    _pipeInterval = FlappyConst.pipeSpacing / notifier.state.pipeSpeed;
  }

  // ─────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!_started || _dead) return;
    if (notifier.state.status == FlappyStatus.dead) return;

    final speed = notifier.state.pipeSpeed;

    // Scroll background
    _bg.scroll(dt, speed);

    // Ground speed sync
    _ground.speed = speed;

    // Spawn pipes
    _pipeTimer += dt;
    _pipeInterval = FlappyConst.pipeSpacing / speed;
    if (_pipeTimer >= _pipeInterval) {
      _pipeTimer = 0;
      _spawnPipe();
    }

    // Move pipes
    for (final pipe in List<PipePair>.from(_pipes)) {
      pipe.position.x -= speed * dt;

      // Score when bird passes pipe centre
      if (!pipe.scored && pipe.rightEdge < _bird.position.x) {
        pipe.scored = true;
        notifier.addScore();
        HapticFeedback.lightImpact();
        add(ScorePopup(position: _bird.position.clone()..y -= 40));
      }

      // Remove off-screen pipes
      if (pipe.position.x + FlappyConst.pipeWidth < -20) {
        pipe.removeFromParent();
        _pipes.remove(pipe);
      }
    }

    // Collision detection
    _checkCollisions();
  }

  // ── Spawn pipe ────────────────────────────
  void _spawnPipe() {
    final score     = notifier.state.score;
    final shrinks   = (score / FlappyConst.gapShrinkEvery).floor();
    final gapSize   = (FlappyConst.pipeGap - shrinks * 8)
        .clamp(FlappyConst.gapMin, FlappyConst.pipeGap);

    final minCentre = gapSize / 2 + 60;
    final maxCentre = _screenH - FlappyConst.groundH - gapSize / 2 - 60;
    final centre    = minCentre + _rng.nextDouble() * (maxCentre - minCentre);

    final pipe = PipePair(
      x:         _screenW + FlappyConst.pipeWidth,
      screenH:   _screenH,
      groundH:   FlappyConst.groundH,
      gapCentre: centre,
      gapSize:   gapSize,
    );
    _pipes.add(pipe);
    add(pipe);
  }

  // ── Collision ─────────────────────────────
  void _checkCollisions() {
    final birdRect = _bird.hitRect;

    // Ground collision
    final groundY = _screenH - FlappyConst.groundH;
    if (_bird.position.y + FlappyConst.birdRadius >= groundY) {
      _triggerDeath();
      return;
    }

    // Ceiling collision
    if (_bird.position.y - FlappyConst.birdRadius <= 0) {
      _triggerDeath();
      return;
    }

    // Pipe collision
    for (final pipe in _pipes) {
      if (pipe.collidesWith(birdRect)) {
        _triggerDeath();
        return;
      }
    }
  }

  void _triggerDeath() {
    if (_dead) return;
    _dead = true;
    HapticFeedback.heavyImpact();
    _bird.die();
    notifier.die();

    add(DeathBurst(position: _bird.position.clone()));
    add(FlappyFlash(screenW: _screenW, screenH: _screenH));
  }

  // ── Tap to flap ───────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    if (!_started) return;
    if (notifier.state.status == FlappyStatus.dead) return;
    _bird.flap();
    HapticFeedback.selectionClick();
  }
}
