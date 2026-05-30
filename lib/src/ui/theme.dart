import 'package:flutter/material.dart';

/// The Pinsel look: a calm dark theme with a warm "cat" accent. Centralised so
/// every screen stays consistent and re-themes in one place.
class PinselTheme {
  PinselTheme._();

  static const Color seed = Color(0xFFF6A23B); // warm amber/ginger
  static const Color bg = Color(0xFF14131A);
  static const Color surface = Color(0xFF1E1C26);

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(surface: surface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.black.withOpacity(0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: const ChipThemeData(showCheckmark: false),
      visualDensity: VisualDensity.comfortable,
    );
  }
}
