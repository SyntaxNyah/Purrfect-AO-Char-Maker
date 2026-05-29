/// A small, *tolerant* INI reader/writer tuned for Attorney Online `char.ini`
/// files.
///
/// It is deliberately forgiving because real-world inis are messy:
///  * keys and section names are matched case-insensitively;
///  * `;` and `#` at the start of a line are comments;
///  * values may themselves contain `#` (the emote field separator);
///  * mangled "run-on" numeric lines such as `1 = 02 = 03 = 0` (seen in the
///    wild, e.g. corrupted `[SoundN]`/`[SoundT]` blocks) are auto-repaired into
///    individual entries when [parse] is called with `repairMangled: true`.
///
/// Ordering is always preserved so files round-trip cleanly.
library;

/// A single `key = value` pair.
class IniEntry {
  IniEntry(this.key, this.value);

  String key;
  String value;

  @override
  String toString() => '$key = $value';
}

/// One `[Section]` and its ordered entries.
class IniSectionData {
  IniSectionData(this.name, [List<IniEntry>? entries])
      : entries = entries ?? <IniEntry>[];

  /// The section name exactly as it should be written (canonical casing).
  String name;

  /// Ordered entries. Duplicate keys are permitted but discouraged.
  final List<IniEntry> entries;

  /// Case-insensitive lookup key.
  String get lookupKey => name.toLowerCase();

  /// First value matching [key] (case-insensitive), or null.
  String? value(String key) {
    final String k = key.toLowerCase();
    for (final IniEntry e in entries) {
      if (e.key.toLowerCase() == k) return e.value;
    }
    return null;
  }

  int? intValue(String key) => int.tryParse((value(key) ?? '').trim());

  double? doubleValue(String key) =>
      double.tryParse((value(key) ?? '').trim());

  bool boolValue(String key, {bool defaultValue = false}) {
    final String? v = value(key);
    if (v == null) return defaultValue;
    final String t = v.trim().toLowerCase();
    return t == 'true' || t == '1' || t == 'yes';
  }

  /// Insert or update [key] in place, preserving its existing position.
  void set(String key, String value) {
    final String k = key.toLowerCase();
    for (final IniEntry e in entries) {
      if (e.key.toLowerCase() == k) {
        e.value = value;
        return;
      }
    }
    entries.add(IniEntry(key, value));
  }

  void remove(String key) {
    final String k = key.toLowerCase();
    entries.removeWhere((IniEntry e) => e.key.toLowerCase() == k);
  }

  bool get isEmpty => entries.isEmpty;

  Map<String, String> asMap() {
    final Map<String, String> m = <String, String>{};
    for (final IniEntry e in entries) {
      m[e.key] = e.value;
    }
    return m;
  }

  /// Entries whose key parses as a non-negative integer, sorted ascending.
  /// Useful for `[Emotions]`, `[SoundN]`, frame-effect sections, etc.
  List<MapEntry<int, String>> numericEntries() {
    final List<MapEntry<int, String>> out = <MapEntry<int, String>>[];
    for (final IniEntry e in entries) {
      final int? n = int.tryParse(e.key.trim());
      if (n != null) out.add(MapEntry<int, String>(n, e.value));
    }
    out.sort((MapEntry<int, String> a, MapEntry<int, String> b) =>
        a.key.compareTo(b.key));
    return out;
  }
}

/// A whole parsed `.ini` document.
class IniDocument {
  IniDocument([List<IniSectionData>? sections])
      : sections = sections ?? <IniSectionData>[];

  /// Ordered sections. Any entries appearing before the first `[Section]`
  /// header are stored in a leading section whose name is the empty string.
  final List<IniSectionData> sections;

  /// Case-insensitive section lookup.
  IniSectionData? section(String name) {
    final String k = name.toLowerCase();
    for (final IniSectionData s in sections) {
      if (s.lookupKey == k) return s;
    }
    return null;
  }

  /// Return the section, creating (and appending) it with canonical [name] if
  /// it does not yet exist.
  IniSectionData sectionOrCreate(String name) {
    return section(name) ??
        (sections..add(IniSectionData(name))).last;
  }

  bool hasSection(String name) => section(name) != null;

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  static final RegExp _sectionHeader = RegExp(r'^\[(.*)\]\s*$');
  static final RegExp _runOnNumeric = RegExp(r'^\s*\d+\s*=.*\d+\s*=');

  /// Parse [text] into a document.
  static IniDocument parse(String text, {bool repairMangled = true}) {
    final IniDocument doc = IniDocument();
    IniSectionData current = IniSectionData('');
    doc.sections.add(current);

    for (String raw in const LineSplitter().convert(text)) {
      final String line = raw.replaceAll('\r', '').trim();
      if (line.isEmpty) continue;
      if (line.startsWith(';') || line.startsWith('#')) continue; // comment

      final Match? header = _sectionHeader.firstMatch(line);
      if (header != null) {
        current = IniSectionData(header.group(1)!.trim());
        doc.sections.add(current);
        continue;
      }

      final int eq = line.indexOf('=');
      if (eq < 0) {
        // A bare token with no `=`; keep it as a valueless key so nothing is
        // silently lost.
        current.entries.add(IniEntry(line, ''));
        continue;
      }

      final String key = line.substring(0, eq).trim();
      final String value = line.substring(eq + 1).trim();

      if (repairMangled &&
          int.tryParse(key) != null &&
          _runOnNumeric.hasMatch(line)) {
        final List<IniEntry>? repaired = _repairNumericRun(key, value);
        if (repaired != null) {
          current.entries.addAll(repaired);
          continue;
        }
      }

      current.entries.add(IniEntry(key, value));
    }

    // Drop the synthetic leading section if it never collected anything.
    if (doc.sections.isNotEmpty &&
        doc.sections.first.name.isEmpty &&
        doc.sections.first.isEmpty) {
      doc.sections.removeAt(0);
    }
    return doc;
  }

  /// Attempt to split a run-on line like `1 = 02 = 03 = 0` (here the leading
  /// `key` is `"1"` and `rest` is `"02 = 03 = 0"`).
  ///
  /// Numeric keys in AO sound sections are sequential emote numbers, so we use
  /// the *expected next key* (previous + 1) to disambiguate glued boundaries
  /// such as `...sfx-deskslam10 = 0` (value `sfx-deskslam`, next key `10`) or
  /// `...104 = ...` (value `10`, next key `4`). Returns null if it cannot make
  /// confident sense of the line, in which case the caller keeps it verbatim.
  static List<IniEntry>? _repairNumericRun(String key, String rest) {
    final List<IniEntry> out = <IniEntry>[];
    int currentKey = int.parse(key);
    String remaining = rest;

    // Hard cap to avoid pathological loops on adversarial input.
    for (int guard = 0; guard < 100000; guard++) {
      final int expectedNext = currentKey + 1;
      // Find the next key's digits glued to the end of this value. The trailing
      // negative lookahead stops us matching a prefix of a longer number (so
      // expecting `1` won't match inside `10`). We intentionally do NOT use a
      // leading lookbehind: the next key is usually glued right after the value
      // digits (e.g. value `0` then key `2` in `...= 02 = ...`).
      final RegExp nextMarker = RegExp('$expectedNext(?![0-9])\\s*=');
      final Match? m = nextMarker.firstMatch(remaining);
      if (m == null) {
        out.add(IniEntry('$currentKey', remaining.trim()));
        return out.length >= 2 ? out : null;
      }
      final String value = remaining.substring(0, m.start).trim();
      out.add(IniEntry('$currentKey', value));
      currentKey = expectedNext;
      remaining = remaining.substring(m.end).trim();
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Render the document back to text. A blank line separates sections.
  String serialize() {
    final StringBuffer sb = StringBuffer();
    bool first = true;
    for (final IniSectionData s in sections) {
      if (s.name.isEmpty && s.isEmpty) continue;
      if (!first) sb.writeln();
      first = false;
      if (s.name.isNotEmpty) sb.writeln('[${s.name}]');
      for (final IniEntry e in s.entries) {
        sb.writeln('${e.key} = ${e.value}');
      }
    }
    return sb.toString();
  }

  @override
  String toString() => serialize();
}

/// Minimal, dependency-free line splitter (avoids importing dart:convert just
/// for [LineSplitter] semantics — but we mirror its behaviour exactly).
class LineSplitter {
  const LineSplitter();

  List<String> convert(String data) => data.split(RegExp(r'\r\n|\r|\n'));
}
