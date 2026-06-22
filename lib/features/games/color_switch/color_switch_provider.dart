import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'color_switch_styles.dart';
import '../../../core/services/score_persistence_service.dart';

// ─────────────────────────────────────────────
//  COLOR SWITCH TAP – DATA MODELS
// ─────────────────────────────────────────────

class Obstacle {
  double y;             // centre‑Y in world coords
  double rotation;
  final double rotationSpeed;
  bool scored;

  Obstacle({required this.y, required this.rotation, required this.rotationSpeed, this.scored = false});
}

class ColorSwitcher {
  double y;
  bool consumed;
  ColorSwitcher({required this.y, this.consumed = false});
}

enum CSStatus { idle, playing, dead }

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────

class CSState {
  final double            ballY;
  final double            ballVelocity;
  final Color             ballColor;
  final List<Obstacle>    obstacles;
  final List<ColorSwitcher> switchers;
  final int               score;
  final int               bestScore;
  final double            speed;
  final CSStatus          status;

  const CSState({
    this.ballY        = 0,
    this.ballVelocity = 0,
    this.ballColor    = CSColors.red,
    this.obstacles    = const [],
    this.switchers    = const [],
    this.score        = 0,
    this.bestScore    = 0,
    this.speed        = CSConst.scrollSpeed,
    this.status       = CSStatus.idle,
  });

  int get coins => score ~/ CSConst.coinsPerScore;

  CSState copyWith({
    double?             ballY,
    double?             ballVelocity,
    Color?              ballColor,
    List<Obstacle>?     obstacles,
    List<ColorSwitcher>? switchers,
    int?                score,
    int?                bestScore,
    double?             speed,
    CSStatus?           status,
  }) =>
      CSState(
        ballY:        ballY        ?? this.ballY,
        ballVelocity: ballVelocity ?? this.ballVelocity,
        ballColor:    ballColor    ?? this.ballColor,
        obstacles:    obstacles    ?? this.obstacles,
        switchers:    switchers    ?? this.switchers,
        score:        score        ?? this.score,
        bestScore:    bestScore    ?? this.bestScore,
        speed:        speed        ?? this.speed,
        status:       status       ?? this.status,
      );
}

// ─────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────

class CSNotifier extends StateNotifier<CSState> {
  CSNotifier() : super(const CSState()) {
    _loadSavedBestScore();
  }

  final _scoreSvc = ScorePersistenceService();
  static const String _gameId = 'color_switch';
  final _rng = Random();

  // ── helpers ─────────────────────────────────
  Color _randomColor() => CSColors.gameColors[_rng.nextInt(4)];

  Color _differentColor(Color from) {
    final others = CSColors.gameColors.where((c) => c != from).toList();
    return others[_rng.nextInt(others.length)];
  }

  // ── start ───────────────────────────────────
  void startGame(double screenH) {
    final ballStart = screenH * 0.65;
    final obstacles = <Obstacle>[];
    final switchers = <ColorSwitcher>[];

    // Spawn 3 initial obstacles above the ball
    for (int i = 0; i < 3; i++) {
      final oY = ballStart - CSConst.obstacleGap * (i + 1);
      final rotSpeed = (_rng.nextDouble() * 0.8 + 0.5) * 
                       CSConst.obstacleRotationSpeed * 
                       (_rng.nextBool() ? 1 : -1);
      obstacles.add(Obstacle(
        y: oY,
        rotation: _rng.nextDouble() * 2 * pi,
        rotationSpeed: rotSpeed,
      ));
      // colour switcher halfway between obstacles
      if (i < 2) {
        switchers.add(ColorSwitcher(
          y: oY + CSConst.obstacleGap / 2,
        ));
      }
    }

    state = CSState(
      ballY:        ballStart,
      ballVelocity: 0,
      ballColor:    _randomColor(),
      obstacles:    obstacles,
      switchers:    switchers,
      bestScore:    state.bestScore,
      status:       CSStatus.playing,
    );
  }

  // ── tap ─────────────────────────────────────
  void tap() {
    if (state.status != CSStatus.playing) return;
    state = state.copyWith(ballVelocity: CSConst.jumpVelocity);
  }

  // ── tick ────────────────────────────────────
  void tick(double dt, double screenH) {
    if (state.status != CSStatus.playing) return;

    // --- ball physics ---
    final newVel = state.ballVelocity + CSConst.gravity * dt;
    var   newY   = state.ballY + newVel * dt;

    // Floor death
    if (newY > screenH + 40) {
      _die();
      return;
    }
    // Ceiling clamp
    if (newY < CSConst.ballRadius) {
      newY = CSConst.ballRadius;
    }

    // --- scroll obstacles down ---
    final spd = state.speed;
    final obstacles = List<Obstacle>.from(state.obstacles);
    final switchers = List<ColorSwitcher>.from(state.switchers);
    var   newScore  = state.score;
    var   newSpeed  = state.speed;
    var   newColor  = state.ballColor;

    for (final o in obstacles) {
      o.y += spd * dt;
      o.rotation = (o.rotation + o.rotationSpeed * dt) % (2 * pi);
    }
    for (final s in switchers) {
      s.y += spd * dt;
    }

    // --- collision detection ---
    for (final o in obstacles) {
      final dist = (newY - o.y).abs();
      // Ball entering the obstacle ring zone
      if (dist < CSConst.obstacleRadius + CSConst.ballRadius &&
          dist > CSConst.obstacleRadius - CSConst.obstacleThickness - CSConst.ballRadius) {
        
        // worldAngle: pi/2 if ball is hitting the bottom edge, -pi/2 if hitting the top edge
        final worldAngle = newY > o.y ? pi / 2 : -pi / 2;
        final localAngle = (worldAngle - o.rotation) % (2 * pi);
        final normalised = localAngle < 0 ? localAngle + 2 * pi : localAngle;
        
        // Add pi/4 because visual drawing is shifted by -pi/4 so quadrants are centered on cardinal directions
        final adjustedAngle = (normalised + pi / 4) % (2 * pi);
        final quadrant = (adjustedAngle / (pi / 2)).floor() % 4;
        final segmentColor = CSColors.gameColors[quadrant];

        if (segmentColor != state.ballColor) {
          _die();
          return;
        }
      }

      // Scoring: ball passed below obstacle centre
      if (!o.scored && o.y > newY + CSConst.obstacleRadius) {
        o.scored = true;
        newScore++;
        newSpeed += CSConst.speedIncrement;
      }
    }

    // --- colour switcher pickup ---
    for (final s in switchers) {
      if (!s.consumed && (newY - s.y).abs() < CSConst.switcherRadius + CSConst.ballRadius) {
        s.consumed = true;
        newColor = _differentColor(state.ballColor);
      }
    }

    // --- recycle obstacles that scrolled off screen ---
    double topmost = obstacles.map((o) => o.y).reduce(min);
    while (obstacles.isNotEmpty && obstacles.first.y > screenH + 100) {
      obstacles.removeAt(0);
      topmost = obstacles.isEmpty ? 0 : obstacles.map((o) => o.y).reduce(min);
      final newOY = topmost - CSConst.obstacleGap;
      final rotSpeed = (_rng.nextDouble() * 0.8 + 0.5) * 
                       CSConst.obstacleRotationSpeed * 
                       (_rng.nextBool() ? 1 : -1);
      obstacles.add(Obstacle(
        y: newOY,
        rotation: _rng.nextDouble() * 2 * pi,
        rotationSpeed: rotSpeed,
      ));
      // New switcher
      switchers.add(ColorSwitcher(y: newOY + CSConst.obstacleGap / 2));
    }

    // Remove consumed/off-screen switchers
    switchers.removeWhere((s) => s.y > screenH + 100);

    state = state.copyWith(
      ballY:        newY,
      ballVelocity: newVel,
      ballColor:    newColor,
      obstacles:    obstacles,
      switchers:    switchers,
      score:        newScore,
      speed:        newSpeed,
      bestScore:    newScore > state.bestScore ? newScore : state.bestScore,
    );

    if (newScore > state.bestScore) {
      _scoreSvc.saveBestScore(_gameId, newScore);
    }
  }

  void _die() {
    final finalScore = state.score > state.bestScore ? state.score : state.bestScore;
    if (state.score > state.bestScore) {
      _scoreSvc.saveBestScore(_gameId, state.score);
    }
    state = state.copyWith(
      ballVelocity: 0,
      status: CSStatus.dead,
      bestScore: finalScore,
    );
  }

  Future<void> _loadSavedBestScore() async {
    final saved = await _scoreSvc.loadBestScore(_gameId);
    if (saved > state.bestScore && mounted) {
      state = state.copyWith(bestScore: saved);
    }
  }
}

final colorSwitchProvider =
    StateNotifierProvider<CSNotifier, CSState>(
  (ref) => CSNotifier(),
);
