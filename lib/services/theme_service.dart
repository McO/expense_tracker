import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

class ThemeService {
  static const String _themeKey = 'theme_mode';

  Future<AppThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? AppThemeMode.system.index;
    return AppThemeMode.values[themeIndex];
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<bool> isDarkMode() async {
    final mode = await getThemeMode();
    if (mode == AppThemeMode.system) {
      // For system mode, we'll return false as default
      // The actual system brightness will be handled by Flutter's ThemeMode.system
      return false;
    }
    return mode == AppThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    final currentMode = await getThemeMode();
    AppThemeMode newMode;

    switch (currentMode) {
      case AppThemeMode.light:
        newMode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        newMode = AppThemeMode.system;
        break;
      case AppThemeMode.system:
        newMode = AppThemeMode.light;
        break;
    }

    await setThemeMode(newMode);
  }
}
