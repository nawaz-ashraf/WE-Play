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
import 'hot_air_balloon_game.dart';
import 'hot_air_balloon_models.dart';
import 'hot_air_balloon_provider.dart';

class HotAirBalloonScreen extends ConsumerStatefulWidget {
  const HotAirBalloonScreen({
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
  ConsumerState<HotAirBalloonScreen> createState() =>
      _HotAirBalloonScreenState();
}

class _HotAirBalloonScreenState extends ConsumerState<HotAirBalloonScreen> {
  static const _gameId = 'hot_air_balloon';

  late HotAirBalloonGame _game;
  late EndlessGameStatsStorage _statsStorage;

  bool _started = false;
  bool _showingGameOver = false;
  bool _showControlHint = false;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _game =
        HotAirBalloonGame(notifier: ref.read(hotAirBalloonProvider.notifier));
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
      _showingGameOver = false;
      _showControlHint = true;
    });

    _game.startGame();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showControlHint = false);
      }
    });
  }

  void _retryGame() {
    setState(() {
      _started = false;
      _showingGameOver = false;
      _showControlHint = false;
      _game =
          HotAirBalloonGame(notifier: ref.read(hotAirBalloonProvider.notifier));
    });

    Future.delayed(const Duration(milliseconds: 100), _startGame);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<HotAirBalloonState>(hotAirBalloonProvider, (previous, next) {
      final justDied = previous?.status != HotAirBalloonStatus.dead &&
          next.status == HotAirBalloonStatus.dead;
      if (!_started || _showingGameOver || !justDied) return;

      _showingGameOver = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleGameOver(next);
      });
    });

    final state = ref.watch(hotAirBalloonProvider);

    return Scaffold(
      backgroundColor: HabColors.background,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              if (!_started) return;
              widget.onActionSound?.call();
              _game.setBurning(true);
            },
            onTapUp: (_) => _game.setBurning(false),
            onTapCancel: () => _game.setBurning(false),
            onHorizontalDragUpdate: (details) {
              if (!_started) return;
              final dx = details.primaryDelta ?? 0;
              if (dx.abs() < 1.5) return;
              _game.setHorizontalInput(dx.sign);
            },
            onHorizontalDragEnd: (_) => _game.setHorizontalInput(0),
            onHorizontalDragCancel: () => _game.setHorizontalInput(0),
            child: GameWidget(game: _game),
          ),
          if (_started)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    EndlessHudPill(
                        label: 'BEST $_highScore', color: HabColors.hudSubtle),
                    const Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${state.score}',
                          style: GoogleFonts.orbitron(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: HabColors.hudText,
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
                            color: HabColors.hudSubtle,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    EndlessHudPill(
                        label: '+${state.coinsEarned}', color: HabColors.coin),
                  ],
                ),
              ),
            ),
          if (_showControlHint && _started)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Text(
                  'Hold to rise • drag to steer',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withAlpha(195),
                  ),
                ).animate().fadeIn(duration: 300.ms).fadeOut(delay: 1600.ms),
              ),
            ),
          if (_started && state.status == HotAirBalloonStatus.playing)
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
                        icon: Icons.arrow_back_rounded,
                        accent: HabColors.balloonPurple,
                        onHoldStart: () {
                          widget.onActionSound?.call();
                          _game.setHorizontalInput(-1);
                        },
                        onHoldEnd: () => _game.setHorizontalInput(0),
                        semanticsLabel: 'Move left',
                      ),
                      const Spacer(),
                      GameControlButton(
                        icon: Icons.arrow_forward_rounded,
                        accent: HabColors.balloonYellow,
                        onHoldStart: () {
                          widget.onActionSound?.call();
                          _game.setHorizontalInput(1);
                        },
                        onHoldEnd: () => _game.setHorizontalInput(0),
                        semanticsLabel: 'Move right',
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
        color: HabColors.background.withAlpha(225),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'BALLOON',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      letterSpacing: 2,
                      color: Colors.white.withAlpha(165),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'HOT AIR\nBALLOON',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: HabColors.balloonPurple,
                      height: 1.05,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap Play or tap anywhere to start\nHold to rise and steer left/right.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: HabColors.hudSubtle,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'bird  cloud  pole  drone  kite',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white.withAlpha(170),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'best: $_highScore',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      color: HabColors.coin,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HabColors.balloonPurple,
                      foregroundColor: Colors.white,
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
                    'TODO: Hook optional tap/burn SFX in onActionSound callback.',
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
      ),
    );
  }

  Future<void> _handleGameOver(HotAirBalloonState state) async {
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
        gameTitle: 'Hot Air Balloon',
        score: state.score,
        highScore: _highScore,
        coinsEarned: coinsEarned,
        isNewHighScore: isNewHigh,
        onRetry: () {
          Navigator.pop(context);
          _retryGame();
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
