import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'doodle_models.dart';
import '../../../core/services/score_persistence_service.dart';

class DoodleState {
  const DoodleState({
    this.status = DoodleStatus.idle,
    this.doodlerX = 0,
    this.doodlerY = 0,
    this.doodlerVY = 0,
    this.horizontalInput = 0,
    this.facingRight = true,
    this.platforms = const [],
    this.coins = const [],
    this.scrollOffset = 0,
    this.score = 0,
    this.bestScore = 0,
    this.coinPickups = 0,
    this.coinsEarned = 0,
  });

  final DoodleStatus status;
  final double doodlerX;
  final double doodlerY;
  final double doodlerVY;
  final double horizontalInput;
  final bool facingRight;
  final List<DoodlePlatform> platforms;
  final List<DoodleCoin> coins;
  final double scrollOffset;
  final int score;
  final int bestScore;
  final int coinPickups;
  final int coinsEarned;

  DoodleState copyWith({
    DoodleStatus? status,
    double? doodlerX,
    double? doodlerY,
    double? doodlerVY,
    double? horizontalInput,
    bool? facingRight,
    List<DoodlePlatform>? platforms,
    List<DoodleCoin>? coins,
    double? scrollOffset,
    int? score,
    int? bestScore,
    int? coinPickups,
    int? coinsEarned,
  }) {
    return DoodleState(
      status: status ?? this.status,
      doodlerX: doodlerX ?? this.doodlerX,
      doodlerY: doodlerY ?? this.doodlerY,
      doodlerVY: doodlerVY ?? this.doodlerVY,
      horizontalInput: horizontalInput ?? this.horizontalInput,
      facingRight: facingRight ?? this.facingRight,
      platforms: platforms ?? this.platforms,
      coins: coins ?? this.coins,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      coinPickups: coinPickups ?? this.coinPickups,
      coinsEarned: coinsEarned ?? this.coinsEarned,
    );
  }
}

class DoodleNotifier extends StateNotifier<DoodleState> {
  DoodleNotifier() : super(const DoodleState()) {
    _loadSavedBestScore();
  }

  final _scoreSvc = ScorePersistenceService();
  static const String _gameId = 'doodle_jump';

  final _rng = Random();
  double _screenW = 400;
  double _screenH = 800;

  void _setStateSafely(DoodleState nextState) {
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

  DoodleState get snapshot => state;

  void init(double width, double height) {
    _screenW = width;
    _screenH = height;
  }

  void startGame() {
    final platforms = _buildInitialPlatforms();
    final startPlatform = platforms.last;

    _setStateSafely(DoodleState(
      status: DoodleStatus.playing,
      doodlerX:
          startPlatform.x + (DoodleConst.platformW - DoodleConst.doodlerW) / 2,
      doodlerY: startPlatform.y - DoodleConst.doodlerH,
      doodlerVY: DoodleConst.bounceVelocity,
      platforms: platforms,
      coins: _initialCoins(platforms),
    ));
  }

  void setHorizontalInput(double value) {
    if (state.status != DoodleStatus.playing) return;
    _setStateSafely(state.copyWith(
      horizontalInput: value,
      facingRight: value >= 0,
    ));
  }

  void tick(double dt) {
    if (state.status != DoodleStatus.playing) return;

    final platforms = state.platforms.map((p) {
      var current = p;
      if (current.type == DoodlePlatformType.moving && !current.broken) {
        var nextX = current.x + current.moveDir * 80 * dt;
        var nextDir = current.moveDir;
        if (nextX <= 0 || nextX >= _screenW - DoodleConst.platformW) {
          nextDir = -nextDir;
          nextX = nextX.clamp(0.0, _screenW - DoodleConst.platformW);
        }
        current = current.copyWith(x: nextX, moveDir: nextDir);
      }

      if (current.broken) {
        current = current.copyWith(breakAnim: current.breakAnim + dt * 3);
      }
      return current;
    }).toList();

    final coins = state.coins
        .map((coin) => coin.copyWith(pulse: coin.pulse + dt * 6))
        .toList();

    double newVY = state.doodlerVY + DoodleConst.gravity * dt;
    double newX =
        state.doodlerX + state.horizontalInput * DoodleConst.moveSpeed * dt;
    double newY = state.doodlerY + newVY * dt;

    if (newX < -DoodleConst.doodlerW / 2) {
      newX = _screenW;
    } else if (newX > _screenW + DoodleConst.doodlerW / 2) {
      newX = 0;
    }

    if (newVY > 0) {
      for (int i = 0; i < platforms.length; i++) {
        final platform = platforms[i];
        if (platform.broken) continue;

        final prevBottom = state.doodlerY + DoodleConst.doodlerH;
        final nextBottom = newY + DoodleConst.doodlerH;
        final platformTop = platform.y;

        final hitsX = newX + DoodleConst.doodlerW > platform.x &&
            newX < platform.x + DoodleConst.platformW;
        final hitsY = prevBottom <= platformTop && nextBottom >= platformTop;

        if (hitsX && hitsY) {
          newVY = platform.type == DoodlePlatformType.spring
              ? DoodleConst.springVelocity
              : DoodleConst.bounceVelocity;
          newY = platform.y - DoodleConst.doodlerH;

          if (platform.type == DoodlePlatformType.breaking) {
            platforms[i] = platform.copyWith(broken: true);
          }
          break;
        }
      }
    }

    double scrollDelta = 0;
    final threshold = _screenH * DoodleConst.scrollThresholdFactor;
    if (newY < threshold) {
      scrollDelta = threshold - newY;
      newY = threshold;

      for (int i = 0; i < platforms.length; i++) {
        platforms[i] = platforms[i].copyWith(y: platforms[i].y + scrollDelta);
      }
      for (int i = 0; i < coins.length; i++) {
        coins[i] = coins[i].copyWith(y: coins[i].y + scrollDelta);
      }
    }

    platforms.removeWhere(
        (p) => p.y > _screenH + 40 || (p.broken && p.breakAnim > 1));

    final topMost =
        platforms.isEmpty ? _screenH : platforms.map((p) => p.y).reduce(min);
    double spawnY = topMost - DoodleConst.platformGap;
    while (spawnY > -220) {
      final platform = _randomPlatform(spawnY);
      platforms.add(platform);

      if (_rng.nextInt(4) == 0) {
        coins.add(
          DoodleCoin(
            x: platform.x + DoodleConst.platformW / 2,
            y: platform.y - 20,
          ),
        );
      }

      spawnY -= DoodleConst.platformGap;
    }

    int coinPickups = state.coinPickups;
    final doodlerRect = Rect.fromLTWH(
      newX + 6,
      newY + 6,
      DoodleConst.doodlerW - 12,
      DoodleConst.doodlerH - 12,
    );

    final remainingCoins = <DoodleCoin>[];
    for (final coin in coins) {
      if (coin.hitRect.overlaps(doodlerRect)) {
        coinPickups++;
      } else if (coin.y <= _screenH + 30) {
        remainingCoins.add(coin);
      }
    }

    final scrollOffset = state.scrollOffset + scrollDelta;
    final score = (scrollOffset / DoodleConst.scoreStep).toInt();
    final coinsEarned = (score ~/ 170) + coinPickups * 3;
    final newBest = score > state.bestScore ? score : state.bestScore;

    if (score > state.bestScore) {
      _scoreSvc.saveBestScore(_gameId, score);
    }

    final isDead = newY > _screenH + 80;

    _setStateSafely(state.copyWith(
      status: isDead ? DoodleStatus.dead : DoodleStatus.playing,
      doodlerX: newX,
      doodlerY: newY,
      doodlerVY: isDead ? 0 : newVY,
      platforms: platforms,
      coins: remainingCoins,
      scrollOffset: scrollOffset,
      score: score,
      bestScore: newBest,
      coinPickups: coinPickups,
      coinsEarned: coinsEarned,
    ));
  }

  List<DoodlePlatform> _buildInitialPlatforms() {
    final result = <DoodlePlatform>[
      DoodlePlatform(
        x: _screenW / 2 - DoodleConst.platformW / 2,
        y: _screenH * 0.82,
        type: DoodlePlatformType.normal,
      ),
    ];

    double y = _screenH * 0.82 - DoodleConst.platformGap;
    while (y > -220) {
      result.add(_randomPlatform(y));
      y -= DoodleConst.platformGap;
    }

    return result;
  }

  List<DoodleCoin> _initialCoins(List<DoodlePlatform> platforms) {
    return platforms
        .where((_) => _rng.nextInt(4) == 0)
        .map(
          (platform) => DoodleCoin(
            x: platform.x + DoodleConst.platformW / 2,
            y: platform.y - 20,
          ),
        )
        .toList();
  }

  DoodlePlatform _randomPlatform(double y) {
    final x = _rng.nextDouble() * (_screenW - DoodleConst.platformW);
    final roll = _rng.nextInt(100);
    final type = roll < 10
        ? DoodlePlatformType.spring
        : roll < 24
            ? DoodlePlatformType.breaking
            : roll < 46
                ? DoodlePlatformType.moving
                : DoodlePlatformType.normal;

    return DoodlePlatform(x: x, y: y, type: type);
  }

  Future<void> _loadSavedBestScore() async {
    final saved = await _scoreSvc.loadBestScore(_gameId);
    if (saved > state.bestScore && mounted) {
      state = state.copyWith(bestScore: saved);
    }
  }
}

final doodleProvider = StateNotifierProvider<DoodleNotifier, DoodleState>(
  (ref) => DoodleNotifier(),
);
