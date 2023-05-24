import 'package:enotes/views/splash.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final ThemeData lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontFamily: 'Roboto',
      ),
      bodyMedium: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontFamily: 'Roboto',
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFCC4F4F),
      foregroundColor: Colors.white,
    ),
  );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF1A1D21),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1D21),
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontFamily: 'Roboto',
      ),
      bodyMedium: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamily: 'Roboto',
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFCC4F4F),
      foregroundColor: Colors.white,
    ),
  );

  static Future<void> initializeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    final systemBrightness = WidgetsBinding.instance.window.platformBrightness;
    final isDeviceInDarkMode = systemBrightness == Brightness.dark;

    final useDarkMode = isDarkMode && isDeviceInDarkMode;
    _applyTheme(useDarkMode);
  }

  static Future<ThemeData> getThemeData() async {
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    final isDeviceInDarkMode = brightness == Brightness.dark;
    final isDarkMode = await getDarkMode();

    final setApplicationTheme = isDarkMode && isDeviceInDarkMode;
    return _buildThemeData(setApplicationTheme);
  }

  static ThemeData _buildThemeData(bool setApplicationTheme) {
    return setApplicationTheme ? darkTheme : lightTheme;
  }

  static Color getBackgroundColor(BuildContext context) {
    final themeData = Theme.of(context);
    return themeData.scaffoldBackgroundColor;
  }

  static Future<void> toggleDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    _applyTheme(isDarkMode);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    return isDarkMode;
  }

  static void _applyTheme(bool isDarkMode) {
    final themeData = _buildThemeData(isDarkMode);
    final navigatorState = navigatorKey.currentState;
    if (navigatorState != null) {
      navigatorState.pushAndRemoveUntil<void>(
        MaterialPageRoute(
          builder: (_) => Container(),
        ),
        (route) => false,
      );
    }
    final newTheme = themeData.copyWith(
      platform: themeData.platform,
      materialTapTargetSize: themeData.materialTapTargetSize,
    );
    runApp(
      MaterialApp(
        theme: newTheme,
        home: SplashPage(),
      ),
    );
  }
}
