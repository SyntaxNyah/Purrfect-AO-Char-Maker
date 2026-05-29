import 'ao_constants.dart';

/// One emote (one button) of a character.
///
/// An emote line in `[Emotions]` looks like:
/// `<n> = <comment>#<preanim>#<sprite>#<modifier>[#<deskmod>]`
/// and is cross-referenced by emote number `<n>` in the `[SoundN]`,
/// `[SoundT]`, `[SoundL]`, `[SoundB]`, `[Videos]` and `[OptionsN]` sections.
class Emote {
  Emote({
    this.comment = 'Blank',
    this.preanim = kNoPreanim,
    this.sprite = '',
    this.modifier = EmoteModifier.idle,
    this.deskMod,
    this.hasDeskField = true,
    this.soundName,
    this.soundDelayTicks,
    this.soundLoop,
    this.blipOverride,
    this.video,
    this.optionsBlock,
  });

  /// The `<comment>` field — the human label shown in the dropdown / on the
  /// button when no icon is found.
  String comment;

  /// The `<preanim>` field — preanimation name, or `-` for none.
  String preanim;

  /// The `<sprite>` field — the base name used to find `(a)`/`(b)`/`(c)` and
  /// static sprites.
  String sprite;

  EmoteModifier modifier;

  /// The optional `<deskmod>` field. `null` means "unspecified" (AO treats this
  /// as [DeskModifier.show]). [hasDeskField] records whether a (possibly empty)
  /// 5th field was present so the line can round-trip byte-for-byte.
  DeskModifier? deskMod;
  bool hasDeskField;

  // ---- Cross-referenced per-emote sound/video/options data ----

  /// `[SoundN]` — sound effect name. `null`/empty/`0`/`1`/`-1` mean "no sound".
  String? soundName;

  /// `[SoundT]` — delay before the sound plays, in 60 ms ticks.
  int? soundDelayTicks;

  /// `[SoundL]` — whether this emote's sound loops.
  bool? soundLoop;

  /// `[SoundB]` — per-emote blip-sound override.
  String? blipOverride;

  /// `[Videos]` — per-emote associated video.
  String? video;

  /// `[OptionsN]` — which `[Options*]` block this emote uses (1 = default).
  int? optionsBlock;

  bool get hasMeaningfulSound {
    final String? s = soundName?.trim();
    if (s == null || s.isEmpty) return false;
    return s != '0' && s != '1' && s != '-1';
  }

  /// Parse the value half of an `[Emotions]` line into an [Emote].
  /// Returns null if the line is too malformed to be an emote.
  static Emote? parseLine(String value) {
    final List<String> f = value.split(kEmoteFieldSeparator);
    if (f.length < 3) return null;
    final bool hasDesk = f.length >= 5;
    final String deskField = hasDesk ? f[4].trim() : '';
    return Emote(
      comment: f[0].trim(),
      preanim: f[1].trim().isEmpty ? kNoPreanim : f[1].trim(),
      sprite: f[2].trim(),
      modifier: EmoteModifier.fromValue(int.tryParse(f.length > 3 ? f[3].trim() : '0') ?? 0),
      deskMod: deskField.isEmpty
          ? null
          : DeskModifier.fromValue(int.tryParse(deskField) ?? DeskModifier.defaultValue.value),
      hasDeskField: hasDesk,
    );
  }

  /// Render the value half of an `[Emotions]` line.
  String toLine() {
    final StringBuffer sb = StringBuffer()
      ..write(comment)
      ..write(kEmoteFieldSeparator)
      ..write(preanim.isEmpty ? kNoPreanim : preanim)
      ..write(kEmoteFieldSeparator)
      ..write(sprite)
      ..write(kEmoteFieldSeparator)
      ..write(modifier.value);
    if (deskMod != null) {
      sb
        ..write(kEmoteFieldSeparator)
        ..write(deskMod!.value);
    } else if (hasDeskField) {
      sb.write(kEmoteFieldSeparator); // preserve trailing empty deskmod field
    }
    return sb.toString();
  }

  Emote copy() => Emote(
        comment: comment,
        preanim: preanim,
        sprite: sprite,
        modifier: modifier,
        deskMod: deskMod,
        hasDeskField: hasDeskField,
        soundName: soundName,
        soundDelayTicks: soundDelayTicks,
        soundLoop: soundLoop,
        blipOverride: blipOverride,
        video: video,
        optionsBlock: optionsBlock,
      );
}
