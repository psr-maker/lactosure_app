import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _initTheme();
  }

  Future<void> _initTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // default = DARK
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;

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
        primary: Color(0xFF334155),
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
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white70,
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

  ThemeData get darkTheme {
    const Color deepGreen = Color(0xFF11192A);
    const background = Color(0xFF0B1325);

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      splashColor: background,

      appBarTheme: const AppBarTheme(
        backgroundColor: deepGreen,
        foregroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Color.fromARGB(255, 7, 218, 218),
          size: 20,
        ),
        titleTextStyle: TextStyle(
          color: Color.fromARGB(255, 7, 218, 218),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      colorScheme: const ColorScheme.light(
        primary: Color(0xFF182334),
        secondary: Color(0xFFADC6FF),
        onPrimary: Colors.white,
        onSecondary: Colors.white70,
        tertiary: Colors.green,
        onTertiary: const Color.fromARGB(255, 16, 134, 109),
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
          color: Colors.white,
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
          fontWeight: FontWeight.w700,
          color: Colors.white70,
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
        //******
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
          color: deepGreen,
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
        //*****
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9BB1D8),
        ),
        //*****
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(255, 255, 157, 10),
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
