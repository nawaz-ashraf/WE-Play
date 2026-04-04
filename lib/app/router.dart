import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/core/providers/game_unlock_provider.dart';
import 'package:we_play/features/auth/auth_screen.dart';
import 'package:we_play/features/auth/splash_screen.dart';
import 'package:we_play/features/games/beat_crash/beat_crash_screen.dart';
import 'package:we_play/features/games/block_blast/block_blast_screen.dart';
import 'package:we_play/features/games/color_switch/color_switch_screen.dart';
import 'package:we_play/features/games/doodle_jump/doodle_jump_screen.dart';
import 'package:we_play/features/games/flappy_bird/flappy_screen.dart';
import 'package:we_play/features/games/game_screen.dart';
import 'package:we_play/features/games/glow_merge/glow_merge_screen.dart';
import 'package:we_play/features/games/hot_air_balloon/hot_air_balloon_screen.dart';
import 'package:we_play/features/games/memory_puzzle/memory_screen.dart';
import 'package:we_play/features/games/micro_heist/heist_screen.dart';
import 'package:we_play/features/games/snake_game/snake_screen.dart';
import 'package:we_play/features/games/trex_runner/trex_runner_screen.dart';
import 'package:we_play/features/games/wood_block/wood_block_screen.dart';
import 'package:we_play/features/lobby/lobby_screen.dart';
import 'package:we_play/features/profile/profile_screen.dart';
import 'package:we_play/features/store/store_screen.dart';

/// Bottom navigation shell for main screens
class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _tabs = [
    '/lobby',
    '/store',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    // Sync bottom nav index with current route
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) {
        _currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: WePlayColors.cardBorder,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != _currentIndex) {
              setState(() => _currentIndex = index);
              context.go(_tabs[index]);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_rounded),
              activeIcon: Icon(Icons.storefront_rounded),
              label: 'Store',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

String? _lockedGameRedirect(BuildContext context, String gameId) {
  final container = ProviderScope.containerOf(context, listen: false);
  final unlockNotifier = container.read(gameUnlockProvider.notifier);
  return unlockNotifier.isUnlocked(gameId) ? null : '/store';
}

/// App-level router configuration using go_router
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/lobby',
          builder: (context, state) => const LobbyScreen(),
        ),
        GoRoute(
          path: '/store',
          builder: (context, state) => const StoreScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/lobby/game/glow_merge',
      builder: (context, state) => const GlowMergeScreen(),
    ),
    GoRoute(
      path: '/lobby/game/beat_crash',
      builder: (context, state) => const BeatCrashScreen(),
    ),
    GoRoute(
      path: '/lobby/game/micro_heist',
      builder: (context, state) => const MicroHeistScreen(),
    ),
    GoRoute(
      path: '/lobby/game/flappy_bird',
      builder: (context, state) => const FlappyBirdScreen(),
    ),
    GoRoute(
      path: '/lobby/game/memory_puzzle',
      builder: (context, state) => const MemoryPuzzleScreen(),
    ),
    GoRoute(
      path: '/lobby/game/snake_game',
      builder: (context, state) => const SnakeGameScreen(),
    ),
    GoRoute(
      path: '/lobby/game/block_blast',
      redirect: (context, state) => _lockedGameRedirect(context, 'block_blast'),
      builder: (context, state) => const BlockBlastScreen(),
    ),
    GoRoute(
      path: '/lobby/game/wood_block',
      redirect: (context, state) => _lockedGameRedirect(context, 'wood_block'),
      builder: (context, state) => const WoodBlockScreen(),
    ),
    GoRoute(
      path: '/lobby/game/color_switch',
      redirect: (context, state) =>
          _lockedGameRedirect(context, 'color_switch'),
      builder: (context, state) => const ColorSwitchScreen(),
    ),
    GoRoute(
      path: '/lobby/game/hot_air_balloon',
      redirect: (context, state) =>
          _lockedGameRedirect(context, 'hot_air_balloon'),
      builder: (context, state) => const HotAirBalloonScreen(),
    ),
    GoRoute(
      path: '/lobby/game/trex_run',
      redirect: (context, state) => _lockedGameRedirect(context, 'trex_run'),
      builder: (context, state) => const TRexRunnerScreen(),
    ),
    GoRoute(
      path: '/lobby/game/doodle_jump',
      redirect: (context, state) => _lockedGameRedirect(context, 'doodle_jump'),
      builder: (context, state) => const DoodleJumpScreen(),
    ),
    GoRoute(
      path: '/lobby/game/:id',
      builder: (context, state) {
        final gameId = state.pathParameters['id']!;
        return GameScreen(gameId: gameId);
      },
    ),
  ],
);
