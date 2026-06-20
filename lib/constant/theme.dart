import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  Future<void> _loadThemeFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get lightTheme {
    const deepGreen = Color(0xFF0F172A);
    const background = Colors.white;

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      splashColor: background,

      appBarTheme: const AppBarTheme(
        backgroundColor: deepGreen,
        foregroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: 20),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      colorScheme: const ColorScheme.light(
        primary: deepGreen,
        secondary: Color(0xFF334155),
        onPrimary: Colors.white,
        tertiary: Color.fromARGB(255, 25, 77, 38),
        error: Colors.red,
        background: Color.fromARGB(255, 255, 157, 10),
      ),

      // TEXT THEME
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        displaySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        headlineLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        headlineMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: deepGreen,
        ),
        headlineSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: deepGreen,
        ),
        titleLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        titleMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(255, 25, 77, 38),
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    const deepGreen = Color.fromARGB(255, 15, 37, 73);
    const background = Color.fromARGB(255, 8, 21, 49);

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: deepGreen,
      splashColor: background,

      appBarTheme: const AppBarTheme(
        backgroundColor: deepGreen,
        foregroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: 20),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      colorScheme: const ColorScheme.light(
        primary: deepGreen,
        secondary: background,
        onPrimary: Colors.white,
        onSecondary: Colors.white70,
        tertiary: Colors.green,
        error: Colors.red,
        background: Color.fromARGB(255, 255, 157, 10),
      ),

      // TEXT THEME
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        //*****
        displaySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        //*****
        headlineLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        //*****
        headlineMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: deepGreen,
        ),
        headlineSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: deepGreen,
        ),
        titleLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: deepGreen,
        ),
        //*****
        titleMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(255, 25, 77, 38),
        ),
        //*****
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color.fromARGB(255, 255, 157, 10),
        ),
        //*****
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color.fromARGB(255, 255, 157, 10),
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }
}
