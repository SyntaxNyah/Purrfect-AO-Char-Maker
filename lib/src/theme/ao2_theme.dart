/// Model of an **Attorney Online 2 / webAO theme** — the thing the AO2 client
/// reads out of `base/themes/<name>/`. Parsed from and serialised back to the
/// real client format (Qt `QSettings` flat INIs): design elements are
/// `name = x, y, w, h`, colours are `name = r, g, b`, fonts are a `name = size`
/// base plus `name_font` / `name_color` / `name_bold` / `name_sharp`.
///
/// Pure Dart (no Flutter) so it powers the editor, the random generator and the
/// export identically. **Lossless**: anything we don't model (bubble timing
/// inis, effects, sfx, custom fonts) is preserved in [otherFiles] and written
/// back verbatim, and images live in [images].
library;

import 'dart:typed_data';

import 'package:collection/collection.dart';

/// One positioned widget in a design ini: `name = x, y, w, h`.
class ThemeElement {
  ThemeElement(this.name, this.x, this.y, this.w, this.h);
  String name;
  int x;
  int y;
  int w;
  int h;

  String get line => '$name = $x, $y, $w, $h';

  ThemeElement copy() => ThemeElement(name, x, y, w, h);
}

/// A colour in a design ini: `name = r, g, b`.
class ThemeColor {
  ThemeColor(this.name, this.r, this.g, this.b);
  String name;
  int r;
  int g;
  int b;

  String get line => '$name = $r, $g, $b';

  /// Opaque ARGB int for the UI colour picker.
  int get argb => 0xFF000000 | (r << 16) | (g << 8) | b;

  set argb(int v) {
    r = (v >> 16) & 0xFF;
    g = (v >> 8) & 0xFF;
    b = v & 0xFF;
  }

  ThemeColor copy() => ThemeColor(name, r, g, b);
}

/// A font block in a fonts ini: a `name = size` base plus the `_font`, `_color`,
/// `_bold` and `_sharp` siblings. Any extra siblings (e.g. `_sender_color`,
/// `_showname_color`) are preserved in [extras] so nothing is lost.
class ThemeFont {
  ThemeFont(
    this.name, {
    this.size = 10,
    this.font = '',
    this.r = 255,
    this.g = 255,
    this.b = 255,
    this.bold = false,
    this.sharp = false,
    Map<String, String>? extras,
  }) : extras = extras ?? <String, String>{};

  String name;
  int size;
  String font;
  int r;
  int g;
  int b;
  bool bold;
  bool sharp;

  /// Extra `name_*` keys we don't model individually (kept verbatim).
  final Map<String, String> extras;

  int get argb => 0xFF000000 | (r << 16) | (g << 8) | b;
  set argb(int v) {
    r = (v >> 16) & 0xFF;
    g = (v >> 8) & 0xFF;
    b = v & 0xFF;
  }

  String serialize() {
    final StringBuffer sb = StringBuffer()
      ..writeln('$name = $size')
      ..writeln('${name}_font = $font')
      ..writeln('${name}_color = $r, $g, $b')
      ..writeln('${name}_bold = ${bold ? 1 : 0}')
      ..writeln('${name}_sharp = ${sharp ? 1 : 0}');
    for (final MapEntry<String, String> e in extras.entries) {
      sb.writeln('${name}_${e.key} = ${e.value}');
    }
    return sb.toString();
  }

  ThemeFont copy() => ThemeFont(name,
      size: size,
      font: font,
      r: r,
      g: g,
      b: b,
      bold: bold,
      sharp: sharp,
      extras: Map<String, String>.of(extras));
}

/// A sound mapping in `courtroom_sounds.ini`: `name = path`.
class ThemeSound {
  ThemeSound(this.name, this.path);
  String name;
  String path;
  String get line => '$name = $path';
}

/// An image asset (background, button, bubble, bar…). [bytes] null = a known
/// slot the theme doesn't override yet.
class ThemeImage {
  ThemeImage(this.fileName, {this.bytes, this.ext = 'png'});
  String fileName;
  Uint8List? bytes;
  String ext;
  bool get isSet => bytes != null;
}

/// One design ini (courtroom or lobby): ordered elements, colours and any other
/// scalar keys (`showname_align`, `*_spacing`, `music_list_animated`, …).
class ThemeDesign {
  final List<ThemeElement> elements = <ThemeElement>[];
  final List<ThemeColor> colors = <ThemeColor>[];
  final List<MapEntry<String, String>> scalars = <MapEntry<String, String>>[];

  ThemeElement? element(String name) =>
      elements.firstWhereOrNull((ThemeElement e) => e.name == name);
  ThemeColor? color(String name) =>
      colors.firstWhereOrNull((ThemeColor c) => c.name == name);
  String? scalar(String name) =>
      scalars.firstWhereOrNull((MapEntry<String, String> e) => e.key == name)?.value;

  ThemeElement upsertElement(String name, int x, int y, int w, int h) {
    final ThemeElement? e = element(name);
    if (e != null) {
      e
        ..x = x
        ..y = y
        ..w = w
        ..h = h;
      return e;
    }
    final ThemeElement n = ThemeElement(name, x, y, w, h);
    elements.add(n);
    return n;
  }

  ThemeColor upsertColor(String name, int r, int g, int b) {
    final ThemeColor? c = color(name);
    if (c != null) {
      c
        ..r = r
        ..g = g
        ..b = b;
      return c;
    }
    final ThemeColor n = ThemeColor(name, r, g, b);
    colors.add(n);
    return n;
  }

  void setScalar(String name, String value) {
    final int i = scalars.indexWhere((MapEntry<String, String> e) => e.key == name);
    if (i >= 0) {
      scalars[i] = MapEntry<String, String>(name, value);
    } else {
      scalars.add(MapEntry<String, String>(name, value));
    }
  }

  String serialize(String title) {
    final StringBuffer sb = StringBuffer()
      ..writeln('# $title — generated by Pinsel AO Char Maker')
      ..writeln();
    for (final ThemeElement e in elements) {
      sb.writeln(e.line);
    }
    if (colors.isNotEmpty) {
      sb..writeln()..writeln('# Colours');
      for (final ThemeColor c in colors) {
        sb.writeln(c.line);
      }
    }
    if (scalars.isNotEmpty) {
      sb..writeln()..writeln('# Other');
      for (final MapEntry<String, String> e in scalars) {
        sb.writeln('${e.key} = ${e.value}');
      }
    }
    return sb.toString();
  }

  static ThemeDesign parse(String text) {
    final ThemeDesign d = ThemeDesign();
    for (final MapEntry<String, String> e in Ao2Theme.parseFlatIni(text)) {
      final List<int>? nums = Ao2Theme.intList(e.value);
      if (nums != null && nums.length == 4) {
        d.elements.add(ThemeElement(e.key, nums[0], nums[1], nums[2], nums[3]));
      } else if (nums != null && nums.length == 3) {
        d.colors.add(ThemeColor(e.key, nums[0], nums[1], nums[2]));
      } else {
        d.scalars.add(MapEntry<String, String>(e.key, e.value));
      }
    }
    return d;
  }
}

/// A complete editable AO2 theme.
class Ao2Theme {
  Ao2Theme(this.name);

  String name;

  /// Courtroom dimensions (read from the `courtroom = 0,0,W,H` element).
  int get width => courtroom.element('courtroom')?.w ?? 1280;
  int get height => courtroom.element('courtroom')?.h ?? 720;

  /// Change the courtroom size to [newW]×[newH]. With [scaleElements], every
  /// other widget's x/y/w/h is scaled proportionally so the layout adapts to the
  /// new resolution (e.g. 720p → 1080p); [scaleFonts] grows font sizes too. The
  /// `courtroom` element itself is always set to `0, 0, newW, newH`.
  void resize(int newW, int newH,
      {bool scaleElements = false, bool scaleFonts = false}) {
    final int oldW = width, oldH = height;
    if (scaleElements && oldW > 0 && oldH > 0) {
      final double fx = newW / oldW, fy = newH / oldH;
      for (final ThemeElement e in courtroom.elements) {
        if (e.name == 'courtroom') continue;
        e.x = (e.x * fx).round();
        e.y = (e.y * fy).round();
        e.w = (e.w * fx).round();
        e.h = (e.h * fy).round();
      }
      if (scaleFonts) {
        final double ff = (fx + fy) / 2;
        for (final ThemeFont f in fonts) {
          f.size = (f.size * ff).round().clamp(1, 400);
        }
      }
    }
    courtroom.upsertElement('courtroom', 0, 0, newW, newH);
  }

  final ThemeDesign courtroom = ThemeDesign();
  final List<ThemeFont> fonts = <ThemeFont>[];
  final List<ThemeSound> sounds = <ThemeSound>[];
  String courtroomCss = '';

  final ThemeDesign lobby = ThemeDesign();
  final List<ThemeFont> lobbyFonts = <ThemeFont>[];
  String lobbyCss = '';

  /// Image assets by file name (e.g. `objection_bubble.webp`).
  final Map<String, ThemeImage> images = <String, ThemeImage>{};

  /// Every other file in the theme folder (bubble timing inis, effects/, sfx/,
  /// fonts/, …), kept verbatim so import → edit → export never loses data.
  final Map<String, Uint8List> otherFiles = <String, Uint8List>{};

  ThemeFont? font(String name) =>
      fonts.firstWhereOrNull((ThemeFont f) => f.name == name);
  ThemeSound? sound(String name) =>
      sounds.firstWhereOrNull((ThemeSound s) => s.name == name);

  // ---------------------------------------------------------------------------
  // Serialisation → the files the AO2 client reads
  // ---------------------------------------------------------------------------

  String serializeDesignIni() => courtroom.serialize('Courtroom design');
  String serializeLobbyDesignIni() => lobby.serialize('Lobby design');

  String serializeFontsIni() => _serializeFonts(fonts, 'Courtroom fonts');
  String serializeLobbyFontsIni() => _serializeFonts(lobbyFonts, 'Lobby fonts');

  String serializeSoundsIni() {
    final StringBuffer sb = StringBuffer()
      ..writeln('# Courtroom sounds — generated by Pinsel AO Char Maker')
      ..writeln();
    for (final ThemeSound s in sounds) {
      sb.writeln(s.line);
    }
    return sb.toString();
  }

  static String _serializeFonts(List<ThemeFont> list, String title) {
    final StringBuffer sb = StringBuffer()
      ..writeln('# $title — generated by Pinsel AO Char Maker')
      ..writeln();
    for (final ThemeFont f in list) {
      sb
        ..write(f.serialize())
        ..writeln();
    }
    return sb.toString();
  }

  /// All files this theme should write, as `relPath -> bytes`, ready to zip into
  /// `themes/<name>/…`. Modeled inis/css are regenerated; images and unmodelled
  /// files are passed through.
  Map<String, Uint8List> buildFiles() {
    final Map<String, Uint8List> out = <String, Uint8List>{};
    void put(String rel, String text) =>
        out[rel] = Uint8List.fromList(text.codeUnits);

    put('courtroom_design.ini', serializeDesignIni());
    put('courtroom_fonts.ini', serializeFontsIni());
    if (sounds.isNotEmpty) put('courtroom_sounds.ini', serializeSoundsIni());
    if (courtroomCss.trim().isNotEmpty) {
      put('courtroom_stylesheets.css', courtroomCss);
    }
    if (lobby.elements.isNotEmpty) put('lobby_design.ini', serializeLobbyDesignIni());
    if (lobbyFonts.isNotEmpty) put('lobby_fonts.ini', serializeLobbyFontsIni());
    if (lobbyCss.trim().isNotEmpty) put('lobby_stylesheets.css', lobbyCss);

    for (final ThemeImage im in images.values) {
      if (im.bytes != null) out[im.fileName] = im.bytes!;
    }
    out.addAll(otherFiles);
    return out;
  }

  // ---------------------------------------------------------------------------
  // Parsing helpers (tolerant flat INI: no sections, # ; // comments)
  // ---------------------------------------------------------------------------

  /// Ordered `key=value` pairs from a flat AO INI, skipping blank/comment/
  /// section lines. Tolerant of `#`, `;`, `//` and `///` comment styles.
  static List<MapEntry<String, String>> parseFlatIni(String text) {
    final List<MapEntry<String, String>> out = <MapEntry<String, String>>[];
    for (final String raw in text.split(RegExp(r'\r\n|\r|\n'))) {
      final String line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#') ||
          line.startsWith(';') ||
          line.startsWith('/') ||
          (line.startsWith('[') && line.endsWith(']'))) {
        continue;
      }
      final int eq = line.indexOf('=');
      if (eq <= 0) continue;
      final String key = line.substring(0, eq).trim();
      final String val = line.substring(eq + 1).trim();
      if (key.isNotEmpty) out.add(MapEntry<String, String>(key, val));
    }
    return out;
  }

  /// Parse `a, b, c` into ints, or null if any part isn't an integer.
  static List<int>? intList(String v) {
    if (!v.contains(',')) {
      final int? n = int.tryParse(v.trim());
      return n == null ? null : <int>[n];
    }
    final List<int> nums = <int>[];
    for (final String p in v.split(',')) {
      final int? n = int.tryParse(p.trim());
      if (n == null) return null;
      nums.add(n);
    }
    return nums;
  }

  /// Parse a `courtroom_fonts.ini` (or lobby variant) into [ThemeFont]s. A base
  /// widget is any key whose value is a bare integer (its size) and which isn't a
  /// `_bold`/`_sharp` flag; its `_font/_color/_bold/_sharp` and any other
  /// `_suffix` siblings attach to it (longest-prefix wins so `ic_chatlog` keeps
  /// `ic_chatlog_showname_color`).
  static List<ThemeFont> parseFonts(String text) {
    final List<MapEntry<String, String>> entries = parseFlatIni(text);
    final Map<String, String> map = <String, String>{
      for (final MapEntry<String, String> e in entries) e.key: e.value,
    };
    // Base widgets, longest first so prefix matching is unambiguous.
    final List<String> bases = <String>[
      for (final MapEntry<String, String> e in entries)
        if (int.tryParse(e.value.trim()) != null &&
            !e.key.endsWith('_bold') &&
            !e.key.endsWith('_sharp'))
          e.key,
    ]..sort((String a, String b) => b.length.compareTo(a.length));

    final Map<String, ThemeFont> byName = <String, ThemeFont>{};
    for (final String w in bases) {
      byName[w] = ThemeFont(w, size: int.tryParse(map[w]!.trim()) ?? 10);
    }

    String? ownerOf(String key) {
      for (final String w in bases) {
        if (key == w) return null; // the base itself
        if (key.startsWith('${w}_')) return w; // longest match (bases sorted)
      }
      return null;
    }

    for (final MapEntry<String, String> e in entries) {
      final String? owner = ownerOf(e.key);
      if (owner == null) continue;
      final ThemeFont f = byName[owner]!;
      final String suffix = e.key.substring(owner.length + 1);
      if (suffix == 'font') {
        f.font = e.value;
      } else if (suffix == 'color') {
        final List<int>? c = intList(e.value);
        if (c != null && c.length >= 3) {
          f.r = c[0];
          f.g = c[1];
          f.b = c[2];
        }
      } else if (suffix == 'bold') {
        f.bold = e.value.trim() == '1';
      } else if (suffix == 'sharp') {
        f.sharp = e.value.trim() == '1';
      } else {
        f.extras[suffix] = e.value;
      }
    }
    // Preserve file order of the base widgets.
    final List<ThemeFont> ordered = <ThemeFont>[];
    for (final MapEntry<String, String> e in entries) {
      final ThemeFont? f = byName[e.key];
      if (f != null && !ordered.contains(f)) ordered.add(f);
    }
    return ordered;
  }

  /// Parse `courtroom_sounds.ini`.
  static List<ThemeSound> parseSounds(String text) => <ThemeSound>[
        for (final MapEntry<String, String> e in parseFlatIni(text))
          ThemeSound(e.key, e.value),
      ];

  static const Set<String> _imageExts = <String>{
    'png', 'webp', 'gif', 'apng', 'jpg', 'jpeg', 'bmp'
  };

  static String _ext(String path) {
    final int dot = path.lastIndexOf('.');
    return dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
  }

  /// Build a theme from a folder's files (`relPath -> bytes`, relative to the
  /// theme root). Modeled inis/css become editable; images go to [images]; every
  /// other file is preserved verbatim in [otherFiles].
  static Ao2Theme fromFiles(String name, Map<String, Uint8List> files) {
    final Ao2Theme t = Ao2Theme(name);
    String text(Uint8List b) => String.fromCharCodes(b);
    files.forEach((String rel, Uint8List bytes) {
      final String low = rel.toLowerCase();
      if (low == 'courtroom_design.ini') {
        final ThemeDesign d = ThemeDesign.parse(text(bytes));
        t.courtroom
          ..elements.clear()
          ..colors.clear()
          ..scalars.clear()
          ..elements.addAll(d.elements)
          ..colors.addAll(d.colors)
          ..scalars.addAll(d.scalars);
      } else if (low == 'courtroom_fonts.ini') {
        t.fonts
          ..clear()
          ..addAll(parseFonts(text(bytes)));
      } else if (low == 'courtroom_sounds.ini') {
        t.sounds
          ..clear()
          ..addAll(parseSounds(text(bytes)));
      } else if (low == 'courtroom_stylesheets.css') {
        t.courtroomCss = text(bytes);
      } else if (low == 'lobby_design.ini') {
        final ThemeDesign d = ThemeDesign.parse(text(bytes));
        t.lobby
          ..elements.addAll(d.elements)
          ..colors.addAll(d.colors)
          ..scalars.addAll(d.scalars);
      } else if (low == 'lobby_fonts.ini') {
        t.lobbyFonts.addAll(parseFonts(text(bytes)));
      } else if (low == 'lobby_stylesheets.css') {
        t.lobbyCss = text(bytes);
      } else if (_imageExts.contains(_ext(rel))) {
        t.images[rel] = ThemeImage(rel, bytes: bytes, ext: _ext(rel));
      } else {
        t.otherFiles[rel] = bytes;
      }
    });
    return t;
  }

  /// Strip a shared leading folder from picked paths (folder pickers often
  /// include the selected folder's own name). Returns `(themeName, files)`.
  static (String, Map<String, Uint8List>) normalizePicked(
      Map<String, Uint8List> picked) {
    final List<String> paths = picked.keys.toList();
    if (paths.isEmpty) return ('theme', picked);
    final String first = paths.first.replaceAll('\\', '/');
    final int slash = first.indexOf('/');
    if (slash <= 0) return ('theme', picked);
    final String top = first.substring(0, slash);
    final bool shared =
        paths.every((String p) => p.replaceAll('\\', '/').startsWith('$top/'));
    if (!shared) return ('theme', picked);
    final Map<String, Uint8List> out = <String, Uint8List>{
      for (final MapEntry<String, Uint8List> e in picked.entries)
        e.key.replaceAll('\\', '/').substring(top.length + 1): e.value,
    };
    return (top, out);
  }

  /// A minimal but valid starter theme (a clean 1280×720 layout) for users who
  /// want to build from scratch rather than import an existing theme.
  static Ao2Theme starter() {
    final Ao2Theme t = Ao2Theme('My Theme');
    final ThemeDesign d = t.courtroom;
    d.elements.addAll(<ThemeElement>[
      ThemeElement('courtroom', 0, 0, 1280, 720),
      ThemeElement('viewport', 0, 0, 1280, 480),
      ThemeElement('ao2_chatbox', 0, 380, 1280, 100),
      ThemeElement('showname', 40, 384, 240, 26),
      ThemeElement('message', 40, 414, 1200, 60),
      ThemeElement('chat_arrow', 1230, 444, 24, 24),
      ThemeElement('ic_chatlog', 0, 0, 300, 360),
      ThemeElement('emotes', 300, 490, 360, 220),
      ThemeElement('hold_it', 670, 490, 130, 40),
      ThemeElement('objection', 810, 490, 130, 40),
      ThemeElement('take_that', 950, 490, 130, 40),
      ThemeElement('witness_testimony', 670, 540, 40, 40),
      ThemeElement('cross_examination', 720, 540, 40, 40),
      ThemeElement('defense_bar', 700, 10, 92, 15),
      ThemeElement('prosecution_bar', 700, 30, 92, 15),
      ThemeElement('change_character', 1090, 600, 150, 30),
      ThemeElement('reload_theme', 1090, 636, 150, 30),
      ThemeElement('call_mod', 1090, 672, 150, 30),
      ThemeElement('settings', 1210, 490, 60, 60),
      ThemeElement('music_list', 980, 60, 300, 300),
      ThemeElement('area_list', 980, 60, 300, 300),
    ]);
    d.colors.addAll(<ThemeColor>[
      ThemeColor('ooc_default_color', 0, 0, 0),
      ThemeColor('ooc_server_color', 210, 210, 0),
      ThemeColor('found_song_color', 80, 160, 200),
      ThemeColor('missing_song_color', 180, 40, 50),
      ThemeColor('area_free_color', 80, 160, 200),
      ThemeColor('area_locked_color', 180, 40, 50),
    ]);
    d.setScalar('showname_align', 'left');
    t.fonts.addAll(<ThemeFont>[
      ThemeFont('showname', size: 12, font: 'Sans', bold: true),
      ThemeFont('message', size: 14, font: 'Sans'),
      ThemeFont('ic_chatlog', size: 12, font: 'Sans'),
      ThemeFont('music_list', size: 11, font: 'Sans'),
      ThemeFont('area_list', size: 11, font: 'Sans'),
    ]);
    return t;
  }
}
