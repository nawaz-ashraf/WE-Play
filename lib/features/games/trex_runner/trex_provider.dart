import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trex_models.dart';

class TrexRunState {
  const TrexRunState({
    this.status = TrexRunStatus.idle,
    this.trexY = 0,
    this.trexVY = 0,
    this.isOnGround = true,
    this.isDucking = false,
    this.duckBlend = 0,
    this.obstacles = const [],
    this.coins = const [],
    this.speed = TrexConst.speedBase,
    this.groundOffset = 0,
    this.score = 0,
    this.coinPickups = 0,
    this.coinsEarned = 0,
    this.spawnTimer = TrexConst.spawnBase,
    this.scoreAccumulator = 0,
    this.isNight = false,
    this.runFrame = 0,
  });

  final TrexRunStatus status;
  final double trexY;
  final double trexVY;
  final bool isOnGround;
  final bool isDucking;
  final double duckBlend;
  final List<TrexObstacle> obstacles;
  final List<TrexCoin> coins;
  final double speed;
  final double groundOffset;
  final int score;
  final int coinPickups;
  final int coinsEarned;
  final double spawnTimer;
  final double scoreAccumulator;
  final bool isNight;
  final int runFrame;

  TrexRunState copyWith({
    TrexRunStatus? status,
    double? trexY,
    double? trexVY,
    bool? isOnGround,
    bool? isDucking,
    double? duckBlend,
    List<TrexObstacle>? obstacles,
    List<TrexCoin>? coins,
    double? speed,
    double? groundOffset,
    int? score,
    int? coinPickups,
    int? coinsEarned,
    double? spawnTimer,
    double? scoreAccumulator,
    bool? isNight,
    int? runFrame,
  }) {
    return TrexRunState(
      status: status ?? this.status,
      trexY: trexY ?? this.trexY,
      trexVY: trexVY ?? this.trexVY,
      isOnGround: isOnGround ?? this.isOnGround,
      isDucking: isDucking ?? this.isDucking,
      duckBlend: duckBlend ?? this.duckBlend,
      obstacles: obstacles ?? this.obstacles,
      coins: coins ?? this.coins,
      speed: speed ?? this.speed,
      groundOffset: groundOffset ?? this.groundOffset,
      score: score ?? this.score,
      coinPickups: coinPickups ?? this.coinPickups,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      spawnTimer: spawnTimer ?? this.spawnTimer,
      scoreAccumulator: scoreAccumulator ?? this.scoreAccumulator,
      isNight: isNight ?? this.isNight,
      runFrame: runFrame ?? this.runFrame,
    );
  }
}

class TrexRunNotifier extends StateNotifier<TrexRunState> {
  TrexRunNotifier() : super(const TrexRunState());

  final _rng = Random();

  double _screenW = 400;
  double _screenH = 800;
  bool _duckHeld = false;
  double _runAnimTimer = 0;

  void _setStateSafely(TrexRunState nextState) {
    if (!mounted) return;

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          state = nextState;
        }
      });
      return;
    }

    state = nextState;
  }

  TrexRunState get snapshot => state;

  void init(double width, double height) {
    _screenW = width;
    _screenH = height;
  }

  double get groundY => _screenH * TrexConst.groundFactor;

  void startGame() {
    _duckHeld = false;
    _runAnimTimer = 0;

    _setStateSafely(TrexRunState(
      status: TrexRunStatus.playing,
      trexY: groundY - TrexConst.trexH,
      isOnGround: true,
      isDucking: false,
      duckBlend: 0,
      speed: TrexConst.speedBase,
      spawnTimer: TrexConst.spawnBase,
    ));
  }

  void jump() {
    if (state.status != TrexRunStatus.playing || !state.isOnGround) return;
    _setStateSafely(state.copyWith(
      trexVY: TrexConst.jumpVelocity,
      isOnGround: false,
      isDucking: false,
      duckBlend: 0,
    ));
  }

  void startDuck() {
    _duckHeld = true;
  }

  void stopDuck() {
    _duckHeld = false;
  }

  void tick(double dt) {
    if (state.status != TrexRunStatus.playing) return;

    _runAnimTimer += dt;
    final runFrame =
        _runAnimTimer > 0.14 ? (state.runFrame == 0 ? 1 : 0) : state.runFrame;
    if (_runAnimTimer > 0.14) {
      _runAnimTimer = 0;
    }

    double newY = state.trexY;
    double newVY = state.trexVY;
    bool onGround = state.isOnGround;

    if (!state.isOnGround) {
      newVY += TrexConst.gravity * dt;
      newY += newVY * dt;
    }

    final standingTop = groundY - TrexConst.trexH;
    if (newY >= standingTop) {
      newY = standingTop;
      newVY = 0;
      onGround = true;
    } else {
      onGround = false;
    }

    final targetBlend = (onGround && _duckHeld) ? 1.0 : 0.0;
    final blendSpeed = min(1, dt * 14);
    final duckBlend =
        state.duckBlend + (targetBlend - state.duckBlend) * blendSpeed;
    final currentTrexH =
        TrexConst.trexH + (TrexConst.trexDuckH - TrexConst.trexH) * duckBlend;

    if (onGround) {
      newY = groundY - currentTrexH;
    }

    final nextScoreAccumulator = state.scoreAccumulator + state.speed * dt;
    final gain = (nextScoreAccumulator / TrexConst.scoreStep).floor();
    final scoreAccumulator = nextScoreAccumulator - gain * TrexConst.scoreStep;
    final newScore = state.score + gain;

    final newSpeed =
        (TrexConst.speedBase + (newScore ~/ 110) * TrexConst.speedInc)
            .clamp(TrexConst.speedBase, TrexConst.speedMax);

    final nextGroundOffset = (state.groundOffset + state.speed * dt) % 60;
    final isNight = (newScore ~/ 650).isOdd;

    final movedObstacles = state.obstacles
        .map((o) => o.copyWith(x: o.x - state.speed * dt))
        .where((o) => o.x > -120)
        .toList();

    final movedCoins = state.coins
        .map((c) => c.copyWith(x: c.x - state.speed * dt))
        .where((c) => c.x > -30)
        .toList();

    double spawnTimer = state.spawnTimer - dt;
    if (spawnTimer <= 0) {
      movedObstacles.add(_spawnObstacle());
      if (_rng.nextInt(4) == 0) {
        movedCoins.add(
          TrexCoin(
            x: _screenW + 22,
            y: groundY - 70 - _rng.nextDouble() * 80,
          ),
        );
      }
      spawnTimer = (TrexConst.spawnBase - newScore / 1800)
          .clamp(TrexConst.spawnMin, TrexConst.spawnBase);
    }

    final trexX = _screenW * TrexConst.trexX;
    final trexRect = Rect.fromLTWH(
      trexX + 5,
      newY + 5,
      TrexConst.trexW - 10,
      currentTrexH - 9,
    );

    final hitObstacle = movedObstacles.any((o) => o.hitRect.overlaps(trexRect));

    int newCoinPickups = state.coinPickups;
    final remainingCoins = <TrexCoin>[];
    for (final coin in movedCoins) {
      if (coin.hitRect.overlaps(trexRect)) {
        newCoinPickups++;
      } else {
        remainingCoins.add(coin);
      }
    }

    final coinsEarned = (newScore ~/ 150) + newCoinPickups * 2;

    _setStateSafely(state.copyWith(
      status: hitObstacle ? TrexRunStatus.dead : TrexRunStatus.playing,
      trexY: newY,
      trexVY: newVY,
      isOnGround: onGround,
      isDucking: duckBlend > 0.6,
      duckBlend: duckBlend,
      obstacles: movedObstacles,
      coins: remainingCoins,
      speed: newSpeed,
      groundOffset: nextGroundOffset,
      score: newScore,
      coinPickups: newCoinPickups,
      coinsEarned: coinsEarned,
      spawnTimer: spawnTimer,
      scoreAccumulator: scoreAccumulator,
      isNight: isNight,
      runFrame: runFrame,
    ));
  }

  TrexObstacle _spawnObstacle() {
    final roll = _rng.nextInt(100);

    if (roll < 30) {
      return TrexObstacle(
        x: _screenW + 20,
        y: groundY - 34,
        width: 20,
        height: 34,
        kind: TrexObstacleKind.cactusSmall,
      );
    }

    if (roll < 52) {
      return TrexObstacle(
        x: _screenW + 20,
        y: groundY - 52,
        width: 24,
        height: 52,
        kind: TrexObstacleKind.cactusTall,
      );
    }

    if (roll < 72) {
      return TrexObstacle(
        x: _screenW + 20,
        y: groundY - 40,
        width: 46,
        height: 40,
        kind: TrexObstacleKind.cactusDouble,
      );
    }

    if (roll < 87) {
      return TrexObstacle(
        x: _screenW + 20,
        y: groundY - TrexConst.trexH - 10,
        width: 48,
        height: 30,
        kind: TrexObstacleKind.birdLow,
      );
    }

    return TrexObstacle(
      x: _screenW + 20,
      y: groundY - TrexConst.trexH * 1.6,
      width: 48,
      height: 30,
      kind: TrexObstacleKind.birdHigh,
    );
  }
}

final trexRunProvider = StateNotifierProvider<TrexRunNotifier, TrexRunState>(
  (ref) => TrexRunNotifier(),
);
