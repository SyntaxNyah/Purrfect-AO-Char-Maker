import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Built-in button/icon **overlay** art, generated procedurally (no asset files,
/// works on every platform, scales to any size). A [border] is laid on top of a
/// button (a frame); a [background] sits behind the sprite.
///
/// Themed sets — Umineko, Danganronpa, kawaii pastels — plus a big palette of
/// plain colours. Each preset is a `build(size)` that returns a fresh RGBA image.
enum OverlayKind { border, background }

typedef OverlayBuilder = img.Image Function(int size);

class OverlayPreset {
  OverlayPreset(this.name, this.category, this.kind, this.build);
  final String name;
  final String category;
  final OverlayKind kind;
  final OverlayBuilder build;
}

// ---- palettes ---------------------------------------------------------------

const int _uGold = 0xD4AF37;
const int _uCrimson = 0x7A0E1A;
const int _uBlood = 0xB11226;
const int _uPurple = 0x3A1F3D;

const int _drPink = 0xFF2E88;
const int _drDespair = 0xE5006E;
const int _drHope = 0xFF6FB5;
const int _drBlack = 0x171717;
const int _drWhite = 0xF5F5F5;

const int _sakura = 0xFFB7C5;
const int _lavender = 0xC9B6E4;
const int _mint = 0xB5EAD7;
const int _peach = 0xFFD9BA;
const int _babyBlue = 0xA8D8EA;
const int _lemon = 0xFDF3A0;
const int _rose = 0xFF9EC4;

/// Name → colour for the big "Colours" set (used for both a frame and a soft bg).
const List<(String, int)> _palette = <(String, int)>[
  ('White', 0xFFFFFF), ('Black', 0x141414), ('Red', 0xE53935),
  ('Crimson', 0xB11226), ('Pink', 0xFF80AB), ('Hot Pink', 0xFF2E88),
  ('Rose', 0xFF9EC4), ('Peach', 0xFFCBA4), ('Orange', 0xFB8C00),
  ('Gold', 0xD4AF37), ('Yellow', 0xFDD835), ('Lime', 0xAEEA00),
  ('Green', 0x43A047), ('Mint', 0xB5EAD7), ('Teal', 0x00897B),
  ('Cyan', 0x26C6DA), ('Sky', 0xA8D8EA), ('Blue', 0x1E88E5),
  ('Indigo', 0x5C6BC0), ('Lavender', 0xC9B6E4), ('Purple', 0x8E24AA),
  ('Lilac', 0xD7BDE2), ('Brown', 0x8D6E63), ('Grey', 0x9E9E9E),
];

class OverlayPresets {
  const OverlayPresets._();

  static final List<OverlayPreset> borders = <OverlayPreset>[
    // Umineko — gilded frames.
    OverlayPreset('Umineko Gold', 'Umineko', OverlayKind.border,
        (int s) => _stack(s, <img.Image>[
              _ring(s, _uGold, thickness: .055, radiusFrac: .06),
              _ring(s, _uGold, inset: .11, thickness: .02, radiusFrac: .04),
            ])),
    OverlayPreset('Umineko Crimson', 'Umineko', OverlayKind.border,
        (int s) => _stack(s, <img.Image>[
              _ring(s, _uCrimson, thickness: .085, radiusFrac: .05),
              _ring(s, _uGold, inset: .085, thickness: .016, radiusFrac: .04),
            ])),
    OverlayPreset('Golden Corners', 'Umineko', OverlayKind.border,
        (int s) => _corners(s, _uGold)),

    // Danganronpa.
    OverlayPreset('DR Pink', 'Danganronpa', OverlayKind.border,
        (int s) => _ring(s, _drPink, thickness: .09, radiusFrac: .04)),
    OverlayPreset('Despair', 'Danganronpa', OverlayKind.border,
        (int s) => _ring(s, _drDespair, thickness: .08, radiusFrac: .2)),
    OverlayPreset('Monokuma', 'Danganronpa', OverlayKind.border,
        (int s) => _splitFrame(s, _drBlack, _drWhite, thickness: .1)),

    // Kawaii pastels.
    OverlayPreset('Sakura', 'Kawaii', OverlayKind.border,
        (int s) => _ring(s, _sakura, thickness: .08, radiusFrac: .24)),
    OverlayPreset('Lavender', 'Kawaii', OverlayKind.border,
        (int s) => _ring(s, _lavender, thickness: .08, radiusFrac: .24)),
    OverlayPreset('Mint', 'Kawaii', OverlayKind.border,
        (int s) => _ring(s, _mint, thickness: .08, radiusFrac: .24)),
    OverlayPreset('Cotton Candy', 'Kawaii', OverlayKind.border,
        (int s) => _gradientRing(s, _sakura, _babyBlue,
            thickness: .09, radiusFrac: .22)),
    OverlayPreset('Pastel Rainbow', 'Kawaii', OverlayKind.border,
        (int s) => _rainbowRing(s, thickness: .1, radiusFrac: .2, pastel: true)),
    OverlayPreset('Heart Corners', 'Kawaii', OverlayKind.border,
        (int s) => _stack(s, <img.Image>[
              _ring(s, _rose, thickness: .045, radiusFrac: .22),
              _cornerHearts(s, _rose),
            ])),

    // Classic.
    OverlayPreset('White Frame', 'Classic', OverlayKind.border,
        (int s) => _ring(s, 0xFFFFFF, thickness: .06)),
    OverlayPreset('Black Frame', 'Classic', OverlayKind.border,
        (int s) => _ring(s, 0x000000, thickness: .06)),
    OverlayPreset('Double Gold', 'Classic', OverlayKind.border,
        (int s) => _stack(s, <img.Image>[
              _ring(s, _uGold, thickness: .035),
              _ring(s, _uGold, inset: .1, thickness: .02),
            ])),

    // Many colours.
    for (final c in _palette)
      OverlayPreset(c.$1, 'Colours', OverlayKind.border,
          (int s) => _ring(s, c.$2, thickness: .08, radiusFrac: .14)),
  ];

  static final List<OverlayPreset> backgrounds = <OverlayPreset>[
    // Umineko.
    OverlayPreset('Umineko Crimson', 'Umineko', OverlayKind.background,
        (int s) => _radial(s, _uBlood, _uCrimson)),
    OverlayPreset('Umineko Night', 'Umineko', OverlayKind.background,
        (int s) => _linear(s, _uPurple, _uCrimson)),
    OverlayPreset('Golden Hour', 'Umineko', OverlayKind.background,
        (int s) => _radial(s, _uGold, _uCrimson)),

    // Danganronpa.
    OverlayPreset('Despair', 'Danganronpa', OverlayKind.background,
        (int s) => _radial(s, _drPink, _drBlack)),
    OverlayPreset('Monokuma', 'Danganronpa', OverlayKind.background,
        (int s) => _diagSplit(s, _drBlack, _drWhite)),
    OverlayPreset('Hope Pink', 'Danganronpa', OverlayKind.background,
        (int s) => _linear(s, _drHope, _drPink)),

    // Kawaii.
    OverlayPreset('Pastel Dream', 'Kawaii', OverlayKind.background,
        (int s) => _linear(s, _sakura, _lavender)),
    OverlayPreset('Cotton Candy', 'Kawaii', OverlayKind.background,
        (int s) => _linear(s, _sakura, _babyBlue, vertical: false)),
    OverlayPreset('Sakura Petals', 'Kawaii', OverlayKind.background,
        (int s) => _dots(s, _sakura, 0xFFFFFF)),
    OverlayPreset('Mint Hearts', 'Kawaii', OverlayKind.background,
        (int s) => _hearts(s, _mint, 0xFFFFFF)),
    OverlayPreset('Peach Hearts', 'Kawaii', OverlayKind.background,
        (int s) => _hearts(s, _peach, 0xFFFFFF)),
    OverlayPreset('Lemon Dots', 'Kawaii', OverlayKind.background,
        (int s) => _dots(s, _lemon, 0xFFFFFF)),
    OverlayPreset('Lavender Sparkle', 'Kawaii', OverlayKind.background,
        (int s) => _sparkles(s, _lavender, 0xFFFFFF)),

    // Vibes.
    OverlayPreset('Rainbow', 'Vibes', OverlayKind.background,
        (int s) => _rainbowBg(s)),
    OverlayPreset('Sunset', 'Vibes', OverlayKind.background,
        (int s) => _linear3(s, 0xFFC371, _rose, _uPurple)),
    OverlayPreset('Ocean', 'Vibes', OverlayKind.background,
        (int s) => _linear(s, _babyBlue, 0x1565C0)),
    OverlayPreset('Vaporwave', 'Vibes', OverlayKind.background,
        (int s) => _linear3(s, 0xFF6AD5, 0xC774E8, 0x8795E8)),

    // Many colours (soft radial of each).
    for (final c in _palette)
      OverlayPreset(c.$1, 'Colours', OverlayKind.background,
          (int s) => _radial(s, _lighten(c.$2, .35), c.$2)),
  ];

  static List<OverlayPreset> forKind(OverlayKind kind) =>
      kind == OverlayKind.border ? borders : backgrounds;
}

// ---- colour helpers ---------------------------------------------------------

int _ri(int c) => (c >> 16) & 0xFF;
int _gi(int c) => (c >> 8) & 0xFF;
int _bi(int c) => c & 0xFF;
int _mix(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);
int _lighten(int c, double t) =>
    (_mix(_ri(c), 255, t) << 16) | (_mix(_gi(c), 255, t) << 8) | _mix(_bi(c), 255, t);

int _hsv(double h, double s, double v) {
  h = h % 360;
  if (h < 0) h += 360;
  final double c = v * s;
  final double x = c * (1 - ((h / 60) % 2 - 1).abs());
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
  return (((r + m) * 255).round() << 16) |
      (((g + m) * 255).round() << 8) |
      ((b + m) * 255).round();
}

// ---- drawing primitives -----------------------------------------------------

img.Image _canvas(int s) => img.Image(width: s, height: s, numChannels: 4);

void _set(img.Image im, int x, int y, int c, [int a = 255]) {
  if (x >= 0 && y >= 0 && x < im.width && y < im.height) {
    im.setPixelRgba(x, y, _ri(c), _gi(c), _bi(c), a);
  }
}

void _fill(img.Image im, int c) {
  for (int y = 0; y < im.height; y++) {
    for (int x = 0; x < im.width; x++) {
      _set(im, x, y, c);
    }
  }
}

img.Image _stack(int s, List<img.Image> layers) {
  final img.Image im = _canvas(s);
  for (final img.Image l in layers) {
    img.compositeImage(im, l, dstX: 0, dstY: 0);
  }
  return im;
}

bool _inRoundRect(double x, double y, double l, double t, double r, double b, double rad) {
  if (x < l || x > r || y < t || y > b) return false;
  if (rad <= 0) return true;
  final double cxl = l + rad, cxr = r - rad, cyt = t + rad, cyb = b - rad;
  double dx, dy;
  if (x < cxl && y < cyt) {
    dx = x - cxl;
    dy = y - cyt;
  } else if (x > cxr && y < cyt) {
    dx = x - cxr;
    dy = y - cyt;
  } else if (x < cxl && y > cyb) {
    dx = x - cxl;
    dy = y - cyb;
  } else if (x > cxr && y > cyb) {
    dx = x - cxr;
    dy = y - cyb;
  } else {
    return true;
  }
  return dx * dx + dy * dy <= rad * rad;
}

/// A rectangular (optionally rounded) frame ring.
img.Image _ring(int s, int color,
    {double inset = 0, double thickness = 0.08, double radiusFrac = 0, int alpha = 255}) {
  final img.Image im = _canvas(s);
  final double ins = inset * s;
  final double t = (thickness * s).clamp(1, s / 2).toDouble();
  final double l = ins, top = ins, r = s - 1 - ins, b = s - 1 - ins;
  final double rad = radiusFrac * s;
  final double innerRad = math.max(0.0, rad - t);
  for (int y = 0; y < s; y++) {
    for (int x = 0; x < s; x++) {
      final double px = x + 0.5, py = y + 0.5;
      final bool outer = _inRoundRect(px, py, l, top, r, b, rad);
      final bool inner = _inRoundRect(px, py, l + t, top + t, r - t, b - t, innerRad);
      if (outer && !inner) _set(im, x, y, color, alpha);
    }
  }
  return im;
}

/// A ring recoloured left→right by a gradient.
img.Image _gradientRing(int s, int c0, int c1, {double thickness = .09, double radiusFrac = .1}) {
  final img.Image im = _ring(s, 0xFFFFFF, thickness: thickness, radiusFrac: radiusFrac);
  for (int y = 0; y < s; y++) {
    for (int x = 0; x < s; x++) {
      final img.Pixel p = im.getPixel(x, y);
      if (p.a > 0) {
        final double t = s <= 1 ? 0 : x / (s - 1);
        im.setPixelRgba(x, y, _mix(_ri(c0), _ri(c1), t), _mix(_gi(c0), _gi(c1), t),
            _mix(_bi(c0), _bi(c1), t), p.a.toInt());
      }
    }
  }
  return im;
}

img.Image _rainbowRing(int s, {double thickness = .1, double radiusFrac = .15, bool pastel = false}) {
  final img.Image im = _ring(s, 0xFFFFFF, thickness: thickness, radiusFrac: radiusFrac);
  for (int y = 0; y < s; y++) {
    for (int x = 0; x < s; x++) {
      final img.Pixel p = im.getPixel(x, y);
      if (p.a > 0) {
        final int col = _hsv((x / s) * 320, pastel ? 0.45 : 0.9, 1.0);
        im.setPixelRgba(x, y, _ri(col), _gi(col), _bi(col), p.a.toInt());
      }
    }
  }
  return im;
}

/// Frame whose left half is [left] and right half [right] (Monokuma).
img.Image _splitFrame(int s, int left, int right, {double thickness = .09}) {
  final img.Image im = _canvas(s);
  final int t = (s * thickness).round().clamp(1, s ~/ 2);
  for (int y = 0; y < s; y++) {
    for (int x = 0; x < s; x++) {
      final int edge = math.min(math.min(x, y), math.min(s - 1 - x, s - 1 - y));
      if (edge < t) _set(im, x, y, x < s / 2 ? left : right);
    }
  }
  return im;
}

/// L-shaped brackets in the four corners.
img.Image _corners(int s, int color, {double thickness = .07, double lenFrac = .3}) {
  final img.Image im = _canvas(s);
  final int t = (s * thickness).round().clamp(1, s);
  final int len = (s * lenFrac).round().clamp(t, s);
  void bar(int x0, int y0, int w, int h) {
    for (int y = y0; y < y0 + h; y++) {
      for (int x = x0; x < x0 + w; x++) {
        _set(im, x, y, color);
      }
    }
  }

  bar(0, 0, len, t);
  bar(0, 0, t, len); // TL
  bar(s - len, 0, len, t);
  bar(s - t, 0, t, len); // TR
  bar(0, s - t, len, t);
  bar(0, s - len, t, len); // BL
  bar(s - len, s - t, len, t);
  bar(s - t, s - len, t, len); // BR
  return im;
}

img.Image _cornerHearts(int s, int color) {
  final img.Image im = _canvas(s);
  final double h = s * 0.12;
  final double off = s * 0.16;
  for (final List<double> c in <List<double>>[
    <double>[off, off],
    <double>[s - off, off],
    <double>[off, s - off],
    <double>[s - off, s - off],
  ]) {
    _drawHeart(im, c[0], c[1], h, color);
  }
  return im;
}

bool _inHeart(double nx, double ny) {
  final double a = nx * nx + ny * ny - 1;
  return a * a * a - nx * nx * ny * ny * ny <= 0;
}

void _drawHeart(img.Image im, double cx, double cy, double h, int color, [int alpha = 235]) {
  final int x0 = (cx - h * 1.3).floor(), x1 = (cx + h * 1.3).ceil();
  final int y0 = (cy - h * 1.3).floor(), y1 = (cy + h * 1.3).ceil();
  for (int y = y0; y <= y1; y++) {
    for (int x = x0; x <= x1; x++) {
      final double nx = (x - cx) / h;
      final double ny = (cy - y) / h + 0.25; // shift so the heart sits centred
      if (_inHeart(nx, ny)) _set(im, x, y, color, alpha);
    }
  }
}

// ---- backgrounds ------------------------------------------------------------

img.Image _linear(int s, int c0, int c1, {bool vertical = true}) {
  final img.Image im = _canvas(s);
  for (int y = 0; y < s; y++) {
    for (int x = 0; x < s; x++) {
      final double t = s <= 1 ? 0 : (vertical ? y : x) / (s - 1);
      im.setPixelRgba(x, y, _mix(_ri(c0), _ri(c1), t), _mix(_gi(c0), _gi(c1), t),
          _mix(_bi(c0), _bi(c1), t), 255);
    }
  }
  return im;
}

img.Image _linear3(int s, int c0, int c1, int c2) {
  final img.Image im = _canvas(s);
  for (int y = 0; y < s; y++) {
    final double f = s <= 1 ? 0 : y / (s - 1);
    final int a = f < 0.5 ? c0 : c1;
    final int b = f < 0.5 ? c1 : c2;
    final double t = f < 0.5 ? f / 0.5 : (f - 0.5) / 0.5;
    for (int x = 0; x < s; x++) {
      im.setPixelRgba(x, y, _mix(_ri(a), _ri(b), t), _mix(_gi(a), _gi(b), t),
          _mix(_bi(a), _bi(b), t), 255);
    }
  }
  return im;
}

img.Image _radial(int s, int inner, int outer) {
  final img.Image im = _canvas(s);
  final double cx = s / 2, cy = s / 2;
  final double maxR = math.sqrt(2) * s / 2;
  for (int y = 0; y < s; y++) {
    for (int x = 0; x < s; x++) {
      final double dx = x - cx, dy = y - cy;
      final double t = (math.sqrt(dx * dx + dy * dy) / maxR).clamp(0.0, 1.0);
      im.setPixelRgba(x, y, _mix(_ri(inner), _ri(outer), t),
          _mix(_gi(inner), _gi(outer), t), _mix(_bi(inner), _bi(outer), t), 255);
    }
  }
  return im;
}

img.Image _diagSplit(int s, int a, int b) {
  final img.Image im = _canvas(s);
  for (int y = 0; y < s; y++) {
    for (int x = 0; x < s; x++) {
      _set(im, x, y, x + y < s ? a : b);
    }
  }
  return im;
}

img.Image _rainbowBg(int s) {
  final img.Image im = _canvas(s);
  for (int y = 0; y < s; y++) {
    final int col = _hsv((y / s) * 320, 0.7, 1.0);
    for (int x = 0; x < s; x++) {
      _set(im, x, y, col);
    }
  }
  return im;
}

img.Image _dots(int s, int bg, int dot, {double cellFrac = .26, double rFrac = .06, int alpha = 190}) {
  final img.Image im = _canvas(s);
  _fill(im, bg);
  final int cell = (s * cellFrac).round().clamp(4, s);
  final double r = s * rFrac;
  int row = 0;
  for (int cyc = cell ~/ 2; cyc < s + cell; cyc += cell) {
    final int xoff = row.isEven ? 0 : cell ~/ 2;
    for (int cxc = cell ~/ 2 - cell; cxc < s + cell; cxc += cell) {
      _disc(im, (cxc + xoff).toDouble(), cyc.toDouble(), r, dot, alpha);
    }
    row++;
  }
  return im;
}

void _disc(img.Image im, double cx, double cy, double r, int color, int alpha) {
  final int x0 = (cx - r).floor(), x1 = (cx + r).ceil();
  final int y0 = (cy - r).floor(), y1 = (cy + r).ceil();
  for (int y = y0; y <= y1; y++) {
    for (int x = x0; x <= x1; x++) {
      final double dx = x - cx, dy = y - cy;
      if (dx * dx + dy * dy <= r * r) _set(im, x, y, color, alpha);
    }
  }
}

img.Image _hearts(int s, int bg, int heart, {double cellFrac = .3, int alpha = 200}) {
  final img.Image im = _canvas(s);
  _fill(im, bg);
  final int cell = (s * cellFrac).round().clamp(6, s);
  final double h = cell * 0.32;
  int row = 0;
  for (int cyc = cell ~/ 2; cyc < s + cell; cyc += cell) {
    final int xoff = row.isEven ? 0 : cell ~/ 2;
    for (int cxc = cell ~/ 2 - cell; cxc < s + cell; cxc += cell) {
      _drawHeart(im, (cxc + xoff).toDouble(), cyc.toDouble(), h, heart, alpha);
    }
    row++;
  }
  return im;
}

img.Image _sparkles(int s, int bg, int spark, {double cellFrac = .28, int alpha = 210}) {
  final img.Image im = _canvas(s);
  _fill(im, bg);
  final int cell = (s * cellFrac).round().clamp(6, s);
  final double h = cell * 0.34;
  int row = 0;
  for (int cyc = cell ~/ 2; cyc < s + cell; cyc += cell) {
    final int xoff = row.isEven ? 0 : cell ~/ 2;
    for (int cxc = cell ~/ 2 - cell; cxc < s + cell; cxc += cell) {
      _drawSpark(im, (cxc + xoff).toDouble(), cyc.toDouble(), h, spark, alpha);
    }
    row++;
  }
  return im;
}

/// A 4-point sparkle (an astroid: |x|^0.5 + |y|^0.5 ≤ 1).
void _drawSpark(img.Image im, double cx, double cy, double h, int color, int alpha) {
  final int x0 = (cx - h).floor(), x1 = (cx + h).ceil();
  final int y0 = (cy - h).floor(), y1 = (cy + h).ceil();
  for (int y = y0; y <= y1; y++) {
    for (int x = x0; x <= x1; x++) {
      final double nx = ((x - cx) / h).abs();
      final double ny = ((y - cy) / h).abs();
      if (math.sqrt(nx) + math.sqrt(ny) <= 1.0) _set(im, x, y, color, alpha);
    }
  }
}
