import 'package:flutter/material.dart';

ColorScheme lightColorScheme(context) {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xffab73ff),
    onPrimary: Colors.white,
    secondary: Color(0xFFff71a6),
    onSecondary: Colors.white,
    error: Color(0xFFF32424),
    onError: Colors.white,
    background: Color(0xFFffedff),
    onBackground: Colors.black,
    surface: Color(0xFFc478d9),
    onSurface: Colors.black,
  );
}
