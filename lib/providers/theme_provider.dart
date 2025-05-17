import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define ThemeMode enum if you want system option later
// enum ThemeModeSetting { light, dark, system }

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    // Default to dark mode
    _loadTheme();
  }

  static const _themePrefKey = 'app_theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex =
        prefs.getInt(_themePrefKey) ??
        ThemeMode.dark.index; // Default to dark if not set
    state = ThemeMode.values[themeIndex];
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    if (state != themeMode) {
      state = themeMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePrefKey, themeMode.index);
    }
  }

  void toggleTheme() {
    setTheme(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
