import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.dark(
    background: Color(0xFF121212),     // Dark background
    primary: Color(0xFF3B55E6),        // Keep same blue for consistency
    secondary: Color(0xFF1E1E1E),      // Input field background
    tertiary: Color(0xFF2C2C2C),       // Cards or containers
    inversePrimary: Colors.white,      // Text on dark
  ),
);