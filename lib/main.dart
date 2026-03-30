import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_play/app/app.dart';
import 'package:we_play/core/providers/shared_prefs_provider.dart';
import 'package:we_play/core/services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // We will configure the system UI style dynamically inside WePlayApp

  // TODO: Initialize Firebase when configured
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  final prefs = await SharedPreferences.getInstance();

  // Initialize AdMob SDK and pre-load ads
  final adService = AdService(prefs);
  await adService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const WePlayApp(),
    ),
  );
}

