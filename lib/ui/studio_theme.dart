import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;

abstract final class StudioTheme {
  static const accent = Color(0xff0078d4);
  static const purple = accent;
  static const green = accent;
  static const mint = Color(0xffe5f1fb);
  static const cream = Color(0xfff3f3f3);
  static const ink = Color(0xff1b1b1b);

  static f.FluentThemeData fluent() => f.FluentThemeData(
    brightness: Brightness.light,
    accentColor: f.Colors.blue,
    scaffoldBackgroundColor: cream,
    cardColor: Colors.white,
    visualDensity: VisualDensity.standard,
  );

  // The video package and ink surfaces use Material primitives inside the Fluent shell.
  static ThemeData material(Brightness brightness) => ThemeData(
    brightness: brightness,
    fontFamily: 'Segoe UI',
    colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
        .copyWith(
          primary: accent,
          secondary: accent,
          onSurface: ink,
          surface: Colors.white,
        ),
    scaffoldBackgroundColor: cream,
    splashFactory: NoSplash.splashFactory,
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: 'Segoe UI',
      bodyColor: ink,
      displayColor: ink,
    ),
    dividerColor: const Color(0xffe5e5e5),
    iconTheme: const IconThemeData(color: ink, size: 18),
  );
}
