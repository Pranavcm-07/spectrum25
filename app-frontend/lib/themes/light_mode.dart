import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  colorScheme: ColorScheme.light(
    background: Colors.white,
    primary: Color(0xFF3B55E6),        // Blue button and headings
    secondary: Color(0xFFF2F2F2),       // Input field background
    tertiary: Colors.white,            // General cards or containers
    inversePrimary: Colors.black87,    // Text on white
  ),
);