import 'ao_constants.dart';
import 'ao_ini.dart';

/// A single `frame = value` line inside a `[<sprite>_Frame*]` section.
class FrameEffectEntry {
  FrameEffectEntry(this.frame, this.value);

  /// 1-based frame number of the animation.
  int frame;

  /// For [FrameEffectKind.sfx] this is the sound name; for realization and
  /// screenshake it is conventionally `"1"` (truthy = enabled).
  String value;
}

/// All frame effects of one kind, attached to one sprite reference.
///
/// The sprite reference is the section name with the `_Frame*` suffix removed,
/// e.g. section `[(a)/SlamPloop_FrameSFX]` -> spriteRef `"(a)/SlamPloop"`,
/// kind [FrameEffectKind.sfx].
class FrameEffectSet {
  FrameEffectSet({
    required this.spriteRef,
    required this.kind,
    List<FrameEffectEntry>? entries,
  }) : entries = entries ?? <FrameEffectEntry>[];

  String spriteRef;
  FrameEffectKind kind;
  final List<FrameEffectEntry> entries;

  String get sectionName => kind.sectionSuffix(spriteRef);

  /// Build from a parsed ini section if its name matches one of the
  /// frame-effect suffixes; otherwise returns null.
  static FrameEffectSet? tryFromSection(IniSectionData section) {
    for (final FrameEffectKind kind in FrameEffectKind.values) {
      final String suffix = '_${kind.suffix}';
      if (section.name.toLowerCase().endsWith(suffix.toLowerCase())) {
        final String spriteRef =
            section.name.substring(0, section.name.length - suffix.length);
        final FrameEffectSet set =
            FrameEffectSet(spriteRef: spriteRef, kind: kind);
        for (final MapEntry<int, String> e in section.numericEntries()) {
          set.entries.add(FrameEffectEntry(e.key, e.value));
        }
        return set;
      }
    }
    return null;
  }

  /// Serialise into an [IniSectionData] for writing.
  IniSectionData toSection() {
    final IniSectionData s = IniSectionData(sectionName);
    final List<FrameEffectEntry> sorted = entries.toList()
      ..sort((FrameEffectEntry a, FrameEffectEntry b) =>
          a.frame.compareTo(b.frame));
    for (final FrameEffectEntry e in sorted) {
      s.set('${e.frame}', e.value);
    }
    return s;
  }

  bool get isEmpty => entries.isEmpty;
}
