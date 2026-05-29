import 'ao_constants.dart';
import 'ao_ini.dart';
import 'emote.dart';
import 'frame_effect.dart';

/// Typed view of the `[Options]` block. Unknown keys are preserved in [extra]
/// so no information is ever lost on save.
class CharacterOptions {
  CharacterOptions();

  String name = '';
  String? showname;
  bool? needsShowname;

  /// Raw side id (kept as text so unknown/custom positions survive).
  String side = CourtSide.defaultValue.id;
  String? blips;
  String? chat;
  String? effects;
  String? realization;
  String? category;

  /// Raw scaling id (kept as text).
  String? scaling;
  bool? stretch;

  /// Unmodeled `[Options]` keys, preserved in original order.
  final List<IniEntry> extra = <IniEntry>[];

  CourtSide get sideEnum => CourtSide.fromId(side) ?? CourtSide.defaultValue;
  set sideEnum(CourtSide s) => side = s.id;

  ScalingMode? get scalingEnum =>
      scaling == null ? null : ScalingMode.fromId(scaling!);
}

/// A complete Attorney Online character, parsed losslessly from a `char.ini`.
class Character {
  Character();

  final CharacterOptions options = CharacterOptions();

  /// Alternate `[Options2]`..`[Options5]` blocks, preserved verbatim and keyed
  /// by their block number (2..5).
  final Map<int, List<IniEntry>> alternateOptions = <int, List<IniEntry>>{};

  /// `[Shouts]` section, preserved in order.
  final List<IniEntry> shouts = <IniEntry>[];

  /// Legacy `[Time]` section, preserved in order.
  final List<IniEntry> time = <IniEntry>[];

  final List<Emote> emotes = <Emote>[];

  final List<FrameEffectSet> frameEffects = <FrameEffectSet>[];

  /// `[SoundL]` entries keyed by *sound name* (not emote number) — these loop a
  /// named sound globally and are preserved separately from per-emote looping.
  final List<IniEntry> soundLoopByName = <IniEntry>[];

  /// Any section we do not model is preserved verbatim for round-tripping.
  final List<IniSectionData> unknownSections = <IniSectionData>[];

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  static Character parse(String iniText) =>
      Character.fromIni(IniDocument.parse(iniText));

  static Character fromIni(IniDocument doc) {
    final Character c = Character();

    for (final IniSectionData s in doc.sections) {
      final String key = s.lookupKey;

      if (key == IniSection.options) {
        c._loadOptions(s);
      } else if (key == IniSection.emotions) {
        c._loadEmotions(s);
      } else if (key == IniSection.shouts) {
        c.shouts.addAll(s.entries.map((IniEntry e) => IniEntry(e.key, e.value)));
      } else if (key == IniSection.time) {
        c.time.addAll(s.entries.map((IniEntry e) => IniEntry(e.key, e.value)));
      } else if (_isAlternateOptions(s.name)) {
        final int n = int.parse(s.name.substring('Options'.length));
        c.alternateOptions[n] =
            s.entries.map((IniEntry e) => IniEntry(e.key, e.value)).toList();
      } else if (key == IniSection.soundN ||
          key == IniSection.soundT ||
          key == IniSection.soundL ||
          key == IniSection.soundB ||
          key == IniSection.videos ||
          key == IniSection.optionsN) {
        // Deferred: applied after emotes are known (see below).
        c._pendingPerEmoteSections.add(s);
      } else {
        final FrameEffectSet? fx = FrameEffectSet.tryFromSection(s);
        if (fx != null) {
          c.frameEffects.add(fx);
        } else {
          c.unknownSections.add(s);
        }
      }
    }

    // Apply per-emote sections now that [emotes] is populated.
    for (final IniSectionData s in c._pendingPerEmoteSections) {
      c._applyPerEmoteSection(s);
    }
    c._pendingPerEmoteSections.clear();
    return c;
  }

  final List<IniSectionData> _pendingPerEmoteSections = <IniSectionData>[];

  static bool _isAlternateOptions(String name) {
    final RegExp re = RegExp(r'^Options([2-9])$', caseSensitive: false);
    return re.hasMatch(name);
  }

  void _loadOptions(IniSectionData s) {
    for (final IniEntry e in s.entries) {
      switch (e.key.toLowerCase()) {
        case 'name':
          options.name = e.value;
        case 'showname':
          options.showname = e.value;
        case 'needs_showname':
          options.needsShowname = !e.value.trim().toLowerCase().startsWith('false');
        case 'side':
          options.side = e.value.trim();
        case 'blips':
          options.blips = e.value.trim();
        case 'gender': // legacy alias for blips
          options.blips ??= e.value.trim();
        case 'chat':
          options.chat = e.value.trim();
        case 'effects':
          options.effects = e.value.trim();
        case 'realization':
          options.realization = e.value.trim();
        case 'category':
          options.category = e.value.trim();
        case 'scaling':
          options.scaling = e.value.trim();
        case 'stretch':
          options.stretch = e.value.trim().toLowerCase().startsWith('true');
        default:
          options.extra.add(IniEntry(e.key, e.value));
      }
    }
  }

  void _loadEmotions(IniSectionData s) {
    for (final MapEntry<int, String> e in s.numericEntries()) {
      final Emote? emote = Emote.parseLine(e.value);
      if (emote != null) emotes.add(emote);
    }
  }

  Emote? _emoteAt(int oneBased) {
    final int i = oneBased - 1;
    if (i < 0 || i >= emotes.length) return null;
    return emotes[i];
  }

  void _applyPerEmoteSection(IniSectionData s) {
    final String key = s.lookupKey;
    for (final IniEntry e in s.entries) {
      final int? n = int.tryParse(e.key.trim());
      if (key == IniSection.soundL && n == null) {
        // Named-sound loop entry (e.g. `sound = 1`); preserve separately.
        soundLoopByName.add(IniEntry(e.key, e.value));
        continue;
      }
      if (n == null) continue;
      final Emote? emote = _emoteAt(n);
      if (emote == null) continue;
      switch (key) {
        case IniSection.soundN:
          emote.soundName = e.value;
        case IniSection.soundT:
          emote.soundDelayTicks = int.tryParse(e.value.trim());
        case IniSection.soundL:
          emote.soundLoop = e.value.trim() == '1';
        case IniSection.soundB:
          emote.blipOverride = e.value;
        case IniSection.videos:
          emote.video = e.value;
        case IniSection.optionsN:
          emote.optionsBlock = int.tryParse(e.value.trim());
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  String serialize() => toIni().serialize();

  IniDocument toIni() {
    final IniDocument doc = IniDocument();

    // [Options]
    final IniSectionData opt = IniSectionData('Options');
    if (options.name.isNotEmpty) opt.set('name', options.name);
    if (options.showname != null) opt.set('showname', options.showname!);
    if (options.needsShowname != null) {
      opt.set('needs_showname', options.needsShowname! ? 'true' : 'false');
    }
    if (options.side.isNotEmpty) opt.set('side', options.side);
    if ((options.blips ?? '').isNotEmpty) opt.set('blips', options.blips!);
    if ((options.chat ?? '').isNotEmpty) opt.set('chat', options.chat!);
    if ((options.effects ?? '').isNotEmpty) opt.set('effects', options.effects!);
    if ((options.realization ?? '').isNotEmpty) {
      opt.set('realization', options.realization!);
    }
    if ((options.category ?? '').isNotEmpty) opt.set('category', options.category!);
    if ((options.scaling ?? '').isNotEmpty) opt.set('scaling', options.scaling!);
    if (options.stretch != null) {
      opt.set('stretch', options.stretch! ? 'true' : 'false');
    }
    for (final IniEntry e in options.extra) {
      opt.set(e.key, e.value);
    }
    doc.sections.add(opt);

    // [Options2..5] verbatim
    final List<int> altKeys = alternateOptions.keys.toList()..sort();
    for (final int n in altKeys) {
      final IniSectionData s = IniSectionData('Options$n');
      for (final IniEntry e in alternateOptions[n]!) {
        s.set(e.key, e.value);
      }
      doc.sections.add(s);
    }

    // [Shouts]
    if (shouts.isNotEmpty) {
      final IniSectionData s = IniSectionData('Shouts');
      for (final IniEntry e in shouts) {
        s.set(e.key, e.value);
      }
      doc.sections.add(s);
    }

    // [Time] (legacy)
    if (time.isNotEmpty) {
      final IniSectionData s = IniSectionData('Time');
      for (final IniEntry e in time) {
        s.set(e.key, e.value);
      }
      doc.sections.add(s);
    }

    // [Emotions]
    final IniSectionData emo = IniSectionData('Emotions')
      ..set('number', '${emotes.length}');
    for (int i = 0; i < emotes.length; i++) {
      emo.set('${i + 1}', emotes[i].toLine());
    }
    doc.sections.add(emo);

    // [SoundN] / [SoundT] / [SoundL] / [SoundB] / [Videos] / [OptionsN]
    _emitPerEmote(doc, 'SoundN', (Emote e) => e.hasMeaningfulSound ? e.soundName : null);
    _emitPerEmote(doc, 'SoundT',
        (Emote e) => (e.soundDelayTicks != null && e.soundDelayTicks! > 0)
            ? '${e.soundDelayTicks}'
            : null);
    _emitPerEmote(doc, 'SoundL',
        (Emote e) => (e.soundLoop ?? false) ? '1' : null,
        extra: soundLoopByName);
    _emitPerEmote(doc, 'SoundB', (Emote e) => e.blipOverride);
    _emitPerEmote(doc, 'Videos', (Emote e) => e.video);
    _emitPerEmote(doc, 'OptionsN',
        (Emote e) => e.optionsBlock != null ? '${e.optionsBlock}' : null);

    // Frame effects
    for (final FrameEffectSet fx in frameEffects) {
      if (!fx.isEmpty) doc.sections.add(fx.toSection());
    }

    // Anything we did not model.
    for (final IniSectionData s in unknownSections) {
      doc.sections.add(s);
    }

    return doc;
  }

  void _emitPerEmote(
    IniDocument doc,
    String sectionName,
    String? Function(Emote) selector, {
    List<IniEntry> extra = const <IniEntry>[],
  }) {
    final IniSectionData s = IniSectionData(sectionName);
    for (int i = 0; i < emotes.length; i++) {
      final String? v = selector(emotes[i]);
      if (v != null && v.isNotEmpty) s.set('${i + 1}', v);
    }
    for (final IniEntry e in extra) {
      s.set(e.key, e.value);
    }
    if (!s.isEmpty) doc.sections.add(s);
  }

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// All distinct sprite references used by emotes (idle/talk base names), handy
  /// for associating frame effects and previews.
  Set<String> spriteReferences() =>
      emotes.map((Emote e) => e.sprite).where((String s) => s.isNotEmpty).toSet();
}
