import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hot_air_balloon_models.dart';
import '../../../core/services/score_persistence_service.dart';

class HotAirBalloonState {
  const HotAirBalloonState({
    this.status = HotAirBalloonStatus.idle,
    this.balloonX = 0,
    this.balloonY = 0,
    this.balloonVX = 0,
    this.balloonVY = 0,
    this.isBurning = false,
    this.obstacles = const [],
    this.coins = const [],
    this.worldSpeed = HabConst.worldSpeedBase,
    this.score = 0,
    this.bestScore = 0,
    this.coinPickups = 0,
    this.coinsEarned = 0,
    this.spawnTimer = HabConst.spawnIntervalBase,
    this.distanceAccumulator = 0,
  });

  final HotAirBalloonStatus status;
  final double balloonX;
  final double balloonY;
  final double balloonVX;
  final double balloonVY;
  final bool isBurning;
  final List<HabObstacle> obstacles;
  final List<HabCoin> coins;
  final double worldSpeed;
  final int score;
  final int bestScore;
  final int coinPickups;
  final int coinsEarned;
  final double spawnTimer;
  final double distanceAccumulator;

  HotAirBalloonState copyWith({
    HotAirBalloonStatus? status,
    double? balloonX,
    double? balloonY,
    double? balloonVX,
    double? balloonVY,
    bool? isBurning,
    List<HabObstacle>? obstacles,
    List<HabCoin>? coins,
    double? worldSpeed,
    int? score,
    int? bestScore,
    int? coinPickups,
    int? coinsEarned,
    double? spawnTimer,
    double? distanceAccumulator,
  }) {
    return HotAirBalloonState(
      status: status ?? this.status,
      balloonX: balloonX ?? this.balloonX,
      balloonY: balloonY ?? this.balloonY,
      balloonVX: balloonVX ?? this.balloonVX,
      balloonVY: balloonVY ?? this.balloonVY,
      isBurning: isBurning ?? this.isBurning,
      obstacles: obstacles ?? this.obstacles,
      coins: coins ?? this.coins,
      worldSpeed: worldSpeed ?? this.worldSpeed,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      coinPickups: coinPickups ?? this.coinPickups,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      spawnTimer: spawnTimer ?? this.spawnTimer,
      distanceAccumulator: distanceAccumulator ?? this.distanceAccumulator,
    );
  }
}

class HotAirBalloonNotifier extends StateNotifier<HotAirBalloonState> {
  HotAirBalloonNotifier() : super(const HotAirBalloonState()) {
    _loadSavedBestScore();
  }

  final _scoreSvc = ScorePersistenceService();
  static const String _gameId = 'hot_air_balloon';

  final _rng = Random();
  double _screenW = 400;
  double _screenH = 800;
  double _horizontalInput = 0;

  void _setStateSafely(HotAirBalloonState nextState) {
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

  HotAirBalloonState get snapshot => state;

  void init(double width, double height) {
    _screenW = width;
    _screenH = height;
  }

  void startGame() {
    _horizontalInput = 0;
    _setStateSafely(HotAirBalloonState(
      status: HotAirBalloonStatus.playing,
      balloonX: _screenW * HabConst.balloonStartX,
      balloonY: _screenH * 0.52,
      worldSpeed: HabConst.worldSpeedBase,
      spawnTimer: HabConst.spawnIntervalBase,
    ));
  }

  void setBurning(bool isBurning) {
    if (state.status != HotAirBalloonStatus.playing) return;

    final boostedVY = isBurning && !state.isBurning
        ? (state.balloonVY + HabConst.tapImpulse)
            .clamp(-HabConst.maxVelocity, HabConst.maxVelocity)
        : state.balloonVY;

    _setStateSafely(state.copyWith(
      isBurning: isBurning,
      balloonVY: boostedVY,
    ));
  }

  void setHorizontalInput(double input) {
    if (state.status != HotAirBalloonStatus.playing) return;
    _horizontalInput = input.clamp(-1.0, 1.0);
  }

  void tick(double dt) {
    if (state.status != HotAirBalloonStatus.playing) return;

    final accel = _horizontalInput * HabConst.horizontalAccel;
    final damp = exp(-HabConst.horizontalDamping * dt);
    var nextVX = (state.balloonVX + accel * dt) * damp;
    nextVX = nextVX.clamp(
      -HabConst.horizontalMaxSpeed,
      HabConst.horizontalMaxSpeed,
    );
    var nextX = state.balloonX + nextVX * dt;
    final minX = HabConst.safeSide;
    final maxX = _screenW - HabConst.safeSide - HabConst.balloonW;
    if (nextX < minX) {
      nextX = minX;
      nextVX = 0;
    } else if (nextX > maxX) {
      nextX = maxX;
      nextVX = 0;
    }

    final force = HabConst.gravity + (state.isBurning ? HabConst.burnLift : 0);
    final rawVY = state.balloonVY + force * dt;
    final newVY = rawVY.clamp(-HabConst.maxVelocity, HabConst.maxVelocity);
    final newY = state.balloonY + newVY * dt;

    const topLimit = HabConst.safeTop;
    final bottomLimit = _screenH - HabConst.safeBottom - HabConst.balloonH;
    if (newY <= topLimit || newY >= bottomLimit) {
      _setStateSafely(state.copyWith(
        balloonY: newY.clamp(topLimit, bottomLimit),
        status: HotAirBalloonStatus.dead,
        isBurning: false,
      ));
      return;
    }

    final progressed = state.distanceAccumulator + state.worldSpeed * dt;
    final scoreGain = (progressed / 10).floor();
    final distanceAccumulator = progressed - scoreGain * 10;
    final newScore = state.score + scoreGain;

    final newSpeed =
        (HabConst.worldSpeedBase + (newScore ~/ 110) * HabConst.worldSpeedInc)
            .clamp(HabConst.worldSpeedBase, HabConst.worldSpeedMax);

    final updatedObstacles = state.obstacles.map((o) {
      final nextX = o.x + o.horizontalVelocity * dt;
      final hitLeft = nextX <= 0;
      final hitRight = nextX >= _screenW - o.width;
      final correctedX = nextX.clamp(0.0, _screenW - o.width);

      return o.copyWith(
        x: correctedX,
        y: o.y + state.worldSpeed * dt,
        horizontalVelocity: (hitLeft || hitRight)
            ? -o.horizontalVelocity
            : o.horizontalVelocity,
      );
    }).toList()
      ..removeWhere((o) => o.y > _screenH + 50);

    final updatedCoins = state.coins
        .map((c) => c.copyWith(
              y: c.y + state.worldSpeed * dt,
              pulse: c.pulse + dt * 6,
            ))
        .where((c) => c.y <= _screenH + 40)
        .toList();

    double spawnTimer = state.spawnTimer - dt;
    if (spawnTimer <= 0) {
      updatedObstacles.add(_spawnObstacle());
      if (_rng.nextInt(3) == 0) {
        updatedCoins.add(_spawnCoin());
      }

      spawnTimer = (HabConst.spawnIntervalBase - (newScore / 2000))
          .clamp(HabConst.spawnIntervalMin, HabConst.spawnIntervalBase);
    }

    final balloonRect = Rect.fromLTWH(
      nextX + HabConst.balloonW * 0.14,
      newY + HabConst.balloonH * 0.12,
      HabConst.balloonW * 0.72,
      HabConst.balloonH * 0.74,
    );

    final hitObstacle =
        updatedObstacles.any((o) => o.hitRect.overlaps(balloonRect));

    int newCoinPickups = state.coinPickups;
    final survivingCoins = <HabCoin>[];
    for (final coin in updatedCoins) {
      if (coin.hitRect.overlaps(balloonRect)) {
        newCoinPickups++;
      } else {
        survivingCoins.add(coin);
      }
    }

    final coinsEarned = (newScore ~/ 120) + (newCoinPickups * 2);

    final newBest = newScore > state.bestScore ? newScore : state.bestScore;
    if (newScore > state.bestScore) {
      _scoreSvc.saveBestScore(_gameId, newScore);
    }

    _setStateSafely(state.copyWith(
      balloonX: nextX,
      balloonVX: nextVX,
      balloonY: newY,
      balloonVY: newVY,
      obstacles: updatedObstacles,
      coins: survivingCoins,
      worldSpeed: newSpeed,
      score: newScore,
      bestScore: newBest,
      coinPickups: newCoinPickups,
      coinsEarned: coinsEarned,
      spawnTimer: spawnTimer,
      distanceAccumulator: distanceAccumulator,
      status:
          hitObstacle ? HotAirBalloonStatus.dead : HotAirBalloonStatus.playing,
      isBurning: hitObstacle ? false : state.isBurning,
    ));
  }

  HabObstacle _spawnObstacle() {
    final roll = _rng.nextInt(100);
    final type = roll < 24
        ? HabObstacleType.bird
        : roll < 48
            ? HabObstacleType.cloud
            : roll < 68
                ? HabObstacleType.pole
                : roll < 86
                    ? HabObstacleType.drone
                    : HabObstacleType.kite;

    final size = switch (type) {
      HabObstacleType.bird => const Size(48, 24),
      HabObstacleType.cloud => const Size(94, 52),
      HabObstacleType.pole => const Size(20, 86),
      HabObstacleType.drone => const Size(40, 30),
      HabObstacleType.kite => const Size(44, 52),
    };

    return HabObstacle(
      x: _rng.nextDouble() * (_screenW - size.width),
      y: -size.height - 30,
      width: size.width,
      height: size.height,
      type: type,
      horizontalVelocity: (_rng.nextDouble() * 120) - 60,
    );
  }

  HabCoin _spawnCoin() {
    return HabCoin(
      x: 24 + _rng.nextDouble() * (_screenW - 48),
      y: -40 - _rng.nextDouble() * 90,
    );
  }

  Future<void> _loadSavedBestScore() async {
    final saved = await _scoreSvc.loadBestScore(_gameId);
    if (saved > state.bestScore && mounted) {
      state = state.copyWith(bestScore: saved);
    }
  }
}

final hotAirBalloonProvider =
    StateNotifierProvider<HotAirBalloonNotifier, HotAirBalloonState>(
  (ref) => HotAirBalloonNotifier(),
);
