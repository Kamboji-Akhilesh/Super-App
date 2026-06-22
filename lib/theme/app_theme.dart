import 'package:flutter/material.dart';

/// Centralised Material 3 theming.
///
/// The original palette is preserved, but mapped onto the modern
/// [ColorScheme] fields (`surface`/`onSurface`/`tertiary`) since
/// `background`/`onBackground` were removed from Flutter. The old "background"
/// colour now lives in `surface`, and the purple accent previously stored in
/// `surface` lives in `tertiary` (used by the header/card gradients).
class AppTheme {
  AppTheme._();

  static const ColorScheme _light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xffab73ff),
    onPrimary: Colors.white,
    secondary: Color(0xffff71a6),
    onSecondary: Colors.white,
    tertiary: Color(0xffc478d9),
    onTertiary: Colors.white,
    error: Color(0xfff32424),
    onError: Colors.white,
    surface: Color(0xffffedff),
    onSurface: Colors.black,
  );

  static const ColorScheme _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xffd6bbfc),
    onPrimary: Color(0xff3b255b),
    secondary: Color(0xffffb0c8),
    onSecondary: Color(0xffeaeaea),
    tertiary: Color(0xffe7b6f0),
    onTertiary: Color(0xff462151),
    error: Color(0xfff32424),
    onError: Colors.white,
    surface: Color(0xff202124),
    onSurface: Colors.white,
  );

  static ThemeData light() => _build(_light);
  static ThemeData dark() => _build(_dark);

  static ThemeData _build(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
      );
}
