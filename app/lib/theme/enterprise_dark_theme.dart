import 'package:flutter/material.dart';

/// Enterprise dark theme tokens and component defaults.
class EnterpriseDarkTheme {
  /// Builds the theme.
  static ThemeData build() => ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF121212), colorScheme: const ColorScheme.dark(primary: Color(0xFF4DB6AC), surface: Color(0xFF1E1E1E), error: Color(0xFFEF5350)), cardTheme: CardTheme(color: const Color(0xFF1E1E1E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF262626), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), useMaterial3: true);
}
