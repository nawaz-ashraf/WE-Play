import 'package:flutter/material.dart';
import 'package:we_play/app/theme.dart';
import 'package:we_play/app/router.dart';

/// Root application widget
class WePlayApp extends StatelessWidget {
  const WePlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WE PLAY',
      debugShowCheckedModeBanner: false,
      theme: WePlayTheme.dark,
      routerConfig: appRouter,
    );
  }
}
