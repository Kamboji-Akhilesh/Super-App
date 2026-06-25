import 'package:flutter/material.dart';

/// A note's accent, resolved per-brightness so cards stay legible in both
/// light and dark themes. Card backgrounds are soft tints; the [accent] is the
/// saturated swatch shown in the colour picker and on the pin/marker.
@immutable
class NoteColor {
  const NoteColor({
    required this.name,
    required this.accent,
    required this.lightBg,
    required this.darkBg,
  });

  final String name;
  final Color accent;
  final Color lightBg;
  final Color darkBg;

  Color background(Brightness b) =>
      b == Brightness.dark ? darkBg : lightBg;

  /// Text colour with good contrast on [background].
  Color onBackground(Brightness b) =>
      b == Brightness.dark ? Colors.white : const Color(0xff1c1b1f);
}

/// The fixed palette. Index 0 is the neutral "default" note.
class NotePalette {
  NotePalette._();

  static const List<NoteColor> colors = [
    NoteColor(
      name: 'Default',
      accent: Color(0xff8a8d93),
      lightBg: Color(0xfffbf7ff),
      darkBg: Color(0xff2a2b2e),
    ),
    NoteColor(
      name: 'Lavender',
      accent: Color(0xffab73ff),
      lightBg: Color(0xfff1e8ff),
      darkBg: Color(0xff3a2d52),
    ),
    NoteColor(
      name: 'Rose',
      accent: Color(0xffff71a6),
      lightBg: Color(0xffffe4ee),
      darkBg: Color(0xff532838),
    ),
    NoteColor(
      name: 'Amber',
      accent: Color(0xffffb300),
      lightBg: Color(0xfffff1cc),
      darkBg: Color(0xff4d3a14),
    ),
    NoteColor(
      name: 'Mint',
      accent: Color(0xff26c281),
      lightBg: Color(0xffd9f7ea),
      darkBg: Color(0xff14402f),
    ),
    NoteColor(
      name: 'Sky',
      accent: Color(0xff3b9dff),
      lightBg: Color(0xffdcecff),
      darkBg: Color(0xff14304d),
    ),
    NoteColor(
      name: 'Coral',
      accent: Color(0xffff7043),
      lightBg: Color(0xffffe2d6),
      darkBg: Color(0xff502819),
    ),
  ];

  static NoteColor of(int id) =>
      colors[id >= 0 && id < colors.length ? id : 0];
}
