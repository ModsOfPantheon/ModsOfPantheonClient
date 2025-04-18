import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A237E),
      primary: const Color(0xFF1A237E),
      secondary: const Color(0xFFFFD700),
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A237E),
      foregroundColor: Colors.white,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
      selectedIconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
      selectedLabelTextStyle: const TextStyle(color: Color(0xFFFFD700)),
      unselectedLabelTextStyle: TextStyle(color: Colors.grey[400]),
    ),
    cardTheme: const CardTheme(
      color: Color(0xFF1E1E1E),
      elevation: 2,
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Color(0xFF1E1E1E),
      textColor: Colors.white,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF1A237E),
      ),
    ),
  );
} 