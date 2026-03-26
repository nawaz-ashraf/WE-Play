import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isLight = prefs.getBool(_themeKey) ?? false;
    return isLight ? ThemeMode.light : ThemeMode.dark;
  }

  void toggleTheme() {
    final prefs = ref.read(sharedPreferencesProvider);
    final isCurrentlyLight = state == ThemeMode.light;
    final newMode = isCurrentlyLight ? ThemeMode.dark : ThemeMode.light;
    
    prefs.setBool(_themeKey, newMode == ThemeMode.light);
    state = newMode;
  }
}
