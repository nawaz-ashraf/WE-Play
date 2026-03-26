import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/app/router.dart';
import 'package:we_play/core/providers/theme_provider.dart';

/// Root application widget
class WePlayApp extends ConsumerWidget {
  const WePlayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'WE PLAY',
      debugShowCheckedModeBanner: false,
      theme: WePlayTheme.light,
      darkTheme: WePlayTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
