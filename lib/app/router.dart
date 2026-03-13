import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:we_play/features/auth/splash_screen.dart';
import 'package:we_play/features/auth/auth_screen.dart';
import 'package:we_play/features/lobby/lobby_screen.dart';
import 'package:we_play/features/leaderboard/leaderboard_screen.dart';
import 'package:we_play/features/store/store_screen.dart';
import 'package:we_play/features/profile/profile_screen.dart';
import 'package:we_play/features/games/game_screen.dart';
import 'package:we_play/features/games/glow_merge/glow_merge_screen.dart';
import 'package:we_play/features/games/beat_crash/beat_crash_screen.dart';
import 'package:we_play/app/theme.dart';

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
    '/leaderboard',
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
              icon: Icon(Icons.leaderboard_rounded),
              activeIcon: Icon(Icons.leaderboard_rounded),
              label: 'Ranks',
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
          routes: [
            GoRoute(
              path: 'game/glow_merge',
              builder: (context, state) => const GlowMergeScreen(),
            ),
            GoRoute(
              path: 'game/beat_crash',
              builder: (context, state) => const BeatCrashScreen(),
            ),
            GoRoute(
              path: 'game/:id',
              builder: (context, state) {
                final gameId = state.pathParameters['id']!;
                return GameScreen(gameId: gameId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
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
  ],
);
