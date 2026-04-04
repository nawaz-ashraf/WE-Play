import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_play/core/providers/ad_provider.dart';
import 'package:we_play/core/providers/coin_provider.dart';
import 'package:we_play/core/providers/shared_prefs_provider.dart';
import 'package:we_play/core/providers/user_stats_provider.dart';
import 'package:we_play/features/games/endless_core/endless_game_callbacks.dart';
import 'package:we_play/features/games/endless_core/endless_game_result_sheet.dart';
import 'package:we_play/features/games/endless_core/endless_game_stats_storage.dart';
import 'package:we_play/features/games/endless_core/endless_game_widgets.dart';

import '../glow_merge/coin_service.dart';
import 'trex_game.dart';
import 'trex_models.dart';
import 'trex_provider.dart';

class TRexRunnerScreen extends ConsumerStatefulWidget {
  const TRexRunnerScreen({
    super.key,
    this.onGameOver,
    this.onHighScoreChanged,
    this.onBackToHome,
    this.onGameOverStatusChanged,
    this.onActionSound,
    this.onCollisionSound,
  });

  final EndlessGameOverCallback? onGameOver;
  final EndlessHighScoreChangedCallback? onHighScoreChanged;
  final VoidCallback? onBackToHome;
  final EndlessGameOverStatusCallback? onGameOverStatusChanged;
  final VoidCallback? onActionSound;
  final VoidCallback? onCollisionSound;

  @override
  ConsumerState<TRexRunnerScreen> createState() => _TRexRunnerScreenState();
}

class _TRexRunnerScreenState extends ConsumerState<TRexRunnerScreen> {
  static const _gameId = 'trex_run';

  late TrexRunGame _game;
  late EndlessGameStatsStorage _statsStorage;

  bool _started = false;
  bool _showingGameOver = false;
  bool _showHint = false;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _game = TrexRunGame(notifier: ref.read(trexRunProvider.notifier));
    _statsStorage =
        EndlessGameStatsStorage(ref.read(sharedPreferencesProvider));
    _highScore = _statsStorage.read(_gameId).highScore;
  }

  void _startGame() {
    HapticFeedback.lightImpact();
    widget.onActionSound?.call();
    widget.onGameOverStatusChanged?.call(false);

    setState(() {
      _started = true;
      _showHint = true;
      _showingGameOver = false;
    });

    _game.startGame();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _retry() {
    setState(() {
      _started = false;
      _showHint = false;
      _showingGameOver = false;
      _game = TrexRunGame(notifier: ref.read(trexRunProvider.notifier));
    });

    Future.delayed(const Duration(milliseconds: 100), _startGame);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TrexRunState>(trexRunProvider, (previous, next) {
      final justDied = previous?.status != TrexRunStatus.dead &&
          next.status == TrexRunStatus.dead;
      if (!_started || _showingGameOver || !justDied) return;

      _showingGameOver = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleGameOver(next);
      });
    });

    final state = ref.watch(trexRunProvider);

    return Scaffold(
      backgroundColor: TrexColors.background,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_started) return;
              widget.onActionSound?.call();
              _game.jump();
            },
            onVerticalDragUpdate: (details) {
              if (!_started) return;
              final dy = details.primaryDelta ?? 0;
              if (dy > 5) {
                _game.startDuck();
              } else if (dy < -5) {
                _game.stopDuck();
              }
            },
            onVerticalDragEnd: (_) => _game.stopDuck(),
            child: GameWidget(game: _game),
          ),
          if (_started)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    EndlessHudPill(
                        label: 'BEST $_highScore', color: TrexColors.subtle),
                    const Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${state.score}',
                          style: GoogleFonts.orbitron(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: TrexColors.text,
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(90),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'distance',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: TrexColors.subtle,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    EndlessHudPill(
                        label: '+${state.coinsEarned}', color: TrexColors.coin),
                  ],
                ),
              ),
            ),
          if (_showHint && _started)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 96),
                child: Text(
                  'Tap jump  |  Swipe down duck  |  Buttons below',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withAlpha(190),
                  ),
                ).animate().fadeIn(duration: 300.ms).fadeOut(delay: 1600.ms),
              ),
            ),
          if (_started && state.status == TrexRunStatus.playing)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(45),
                  border: Border(
                    top: BorderSide(color: Colors.white.withAlpha(22)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      GameControlButton(
                        icon: Icons.keyboard_arrow_down_rounded,
                        accent: state.isNight
                            ? TrexColors.nightAccent
                            : TrexColors.dayAccent,
                        onHoldStart: () {
                          widget.onActionSound?.call();
                          _game.startDuck();
                        },
                        onHoldEnd: _game.stopDuck,
                        semanticsLabel: 'Duck',
                      ),
                      const Spacer(),
                      GameControlButton(
                        icon: Icons.arrow_upward_rounded,
                        accent: state.isNight
                            ? TrexColors.nightAccent
                            : TrexColors.dayAccent,
                        onPressed: () {
                          widget.onActionSound?.call();
                          _game.jump();
                        },
                        semanticsLabel: 'Jump',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_started) _buildStartOverlay(),
        ],
      ),
    );
  }

  Widget _buildStartOverlay() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startGame,
      child: Container(
        color: TrexColors.background.withAlpha(225),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'T-REX RUN',
                  style: GoogleFonts.orbitron(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: TrexColors.dayAccent,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap Play or tap screen to begin.\nTap to jump and hold down to duck.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: TrexColors.subtle,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'best: $_highScore',
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    color: TrexColors.coin,
                  ),
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TrexColors.dayAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'PLAY',
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TODO: Hook jump/hit SFX using onActionSound and onCollisionSound.',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: Colors.white.withAlpha(110),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGameOver(TrexRunState state) async {
    if (!mounted) return;

    widget.onCollisionSound?.call();

    final coinsEarned = state.coinsEarned;
    ref.read(coinNotifierProvider.notifier).earnCoins(coinsEarned);
    ref.read(userStatsProvider.notifier).incrementGamesPlayed();

    final isNewHigh = _statsStorage.saveRun(
      gameId: _gameId,
      score: state.score,
      coinsEarned: coinsEarned,
    );

    _highScore = _statsStorage.read(_gameId).highScore;
    if (isNewHigh) {
      widget.onHighScoreChanged?.call(_highScore);
    }

    widget.onGameOverStatusChanged?.call(true);
    widget.onGameOver?.call(state.score, coinsEarned);

    try {
      await CoinService().awardCoins(coinsEarned);
      await CoinService().submitScore(
        gameId: _gameId,
        score: state.score,
        username: 'player',
        avatarUrl: '',
      );
    } catch (_) {}

    await ref.read(adServiceProvider).showInterstitialIfReady();

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => EndlessGameResultSheet(
        gameTitle: 'T-Rex Run',
        score: state.score,
        highScore: _highScore,
        coinsEarned: coinsEarned,
        isNewHighScore: isNewHigh,
        onRetry: () {
          Navigator.pop(context);
          _retry();
        },
        onBackToHome: () {
          Navigator.pop(context);
          widget.onBackToHome?.call();
          Navigator.maybePop(context);
        },
      ),
    );
  }
}
