import 'package:flutter/material.dart';

ColorScheme darkColorScheme(context) {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xffd6bbfc),
    onPrimary: Color(0xFF3b255b),
    secondary: Color(0xFFffb0c8),
    onSecondary: Color(0xFFEAEAEA),
    error: Color(0xFFF32424),
    onError: Color(0xFFF32424),
    background: Color(0xFF202124),
    onBackground: Colors.white,
    surface: Color(0xFFe7b6f0),
    onSurface: Color(0xFF462151),
  );
}
