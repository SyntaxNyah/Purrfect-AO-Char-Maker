import 'dart:math';

import 'ao2_theme.dart';

/// Generates cohesive random AO2 theme palettes (and optionally fonts / a light
/// position jitter). Touches only colours, fonts and — when asked — positions;
/// images are never randomised. Pure Dart so it's deterministic for a given
/// [seed], which makes "re-roll" reproducible and testable.
class ThemeRandomizer {
  const ThemeRandomizer._();

  static const List<String> _fontFamilies = <String>[
    'Sans', 'Arial', 'Verdana', 'Tahoma', 'Trebuchet MS', 'Segoe UI',
    'Georgia', 'Times New Roman', 'Courier New', 'Impact',
  ];

  /// Randomise [t] in place. Returns the seed used (pass it back to reproduce).
  static int randomize(
    Ao2Theme t, {
    int? seed,
    bool colors = true,
    bool fonts = true,
    bool jitterPositions = false,
  }) {
    final int s = seed ?? (DateTime.now().millisecondsSinceEpoch & 0x7fffffff);
    final Random rng = Random(s);
    final _Palette pal = _Palette.random(rng);
    if (colors) _colors(t, rng, pal);
    if (fonts) _fonts(t, rng, pal);
    if (jitterPositions) _jitter(t, rng);
    return s;
  }

  static void _colors(Ao2Theme t, Random rng, _Palette pal) {
    for (final ThemeColor c in t.courtroom.colors) {
      _assign(c, rng, pal);
    }
    for (final ThemeColor c in t.lobby.colors) {
      _assign(c, rng, pal);
    }
  }

  /// Pick a semantically-sensible colour for a named theme colour.
  static void _assign(ThemeColor c, Random rng, _Palette pal) {
    final String n = c.name.toLowerCase();
    List<int> rgb;
    if (n.contains('locked') || n.contains('missing') || n.contains('casing')) {
      rgb = pal.warn;
    } else if (n.contains('free') || n.contains('found') || n.contains('gaming')) {
      rgb = pal.accent;
    } else if (n.contains('recess') || n.contains('rp') || n.contains('lfp')) {
      rgb = pal.secondary;
    } else if (n.startsWith('ooc_default')) {
      rgb = pal.ink;
    } else if (n.startsWith('ooc_server')) {
      rgb = pal.highlight;
    } else {
      rgb = pal.pick(rng);
    }
    c.r = rgb[0];
    c.g = rgb[1];
    c.b = rgb[2];
  }

  static void _fonts(Ao2Theme t, Random rng, _Palette pal) {
    final String family = _fontFamilies[rng.nextInt(_fontFamilies.length)];
    void style(ThemeFont f) {
      f.font = family;
      // Shownames pop in the accent; body text stays readable (light).
      final bool isName = f.name.contains('showname') || f.name.contains('name');
      final List<int> rgb = isName ? pal.highlight : pal.text;
      f.r = rgb[0];
      f.g = rgb[1];
      f.b = rgb[2];
      if (isName) f.bold = rng.nextBool();
    }

    for (final ThemeFont f in t.fonts) {
      style(f);
    }
    for (final ThemeFont f in t.lobbyFonts) {
      style(f);
    }
  }

  static void _jitter(Ao2Theme t, Random rng) {
    for (final ThemeElement e in t.courtroom.elements) {
      if (e.name == 'courtroom' || e.name == 'viewport') continue;
      e.x += rng.nextInt(11) - 5;
      e.y += rng.nextInt(11) - 5;
    }
  }
}

/// A cohesive random palette derived from one base hue (triadic accents).
class _Palette {
  _Palette(this.primary, this.secondary, this.accent, this.warn, this.highlight,
      this.ink, this.text);

  final List<int> primary;
  final List<int> secondary;
  final List<int> accent;
  final List<int> warn;
  final List<int> highlight;
  final List<int> ink;
  final List<int> text;

  static _Palette random(Random rng) {
    final double h = rng.nextDouble() * 360;
    return _Palette(
      _hsv(h, 0.55, 0.75),
      _hsv((h + 150) % 360, 0.5, 0.7),
      _hsv((h + 30) % 360, 0.7, 0.9),
      _hsv((h + 180) % 360, 0.65, 0.8),
      _hsv((h + 45) % 360, 0.85, 0.95),
      <int>[20, 20, 24],
      <int>[235, 235, 240],
    );
  }

  List<int> pick(Random rng) {
    final List<List<int>> all = <List<int>>[primary, secondary, accent, highlight];
    return all[rng.nextInt(all.length)];
  }

  static List<int> _hsv(double h, double s, double v) {
    h %= 360;
    final double c = v * s;
    final double x = c * (1 - (((h / 60) % 2) - 1).abs());
    final double m = v - c;
    double r = 0, g = 0, b = 0;
    if (h < 60) {
      r = c;
      g = x;
    } else if (h < 120) {
      r = x;
      g = c;
    } else if (h < 180) {
      g = c;
      b = x;
    } else if (h < 240) {
      g = x;
      b = c;
    } else if (h < 300) {
      r = x;
      b = c;
    } else {
      r = c;
      b = x;
    }
    return <int>[
      ((r + m) * 255).round().clamp(0, 255),
      ((g + m) * 255).round().clamp(0, 255),
      ((b + m) * 255).round().clamp(0, 255),
    ];
  }
}
