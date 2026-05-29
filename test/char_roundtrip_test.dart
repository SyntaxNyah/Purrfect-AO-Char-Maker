import 'package:flutter_test/flutter_test.dart';
import 'package:purrfect/src/core/ao_constants.dart';
import 'package:purrfect/src/core/character.dart';

const String _sample = '''
[Options]
name = test guy
showname = Tester
side = def
blips = male
scaling = smooth

[Emotions]
number = 3
1 = Normal#-#normal#0#
2 = Point#point_pre#point#1#1
3 = Zoom#-#zoom#5

[SoundN]
2 = sfx-point

[SoundT]
2 = 3

[(b)point_FrameSFX]
2 = sfx-point
''';

void main() {
  group('Character model', () {
    test('parses options, emotes, sounds and frame effects', () {
      final Character c = Character.parse(_sample);
      expect(c.options.name, 'test guy');
      expect(c.options.sideEnum, CourtSide.defense);
      expect(c.emotes.length, 3);

      expect(c.emotes[1].comment, 'Point');
      expect(c.emotes[1].modifier, EmoteModifier.preanim);
      expect(c.emotes[1].deskMod, DeskModifier.show);
      expect(c.emotes[1].soundName, 'sfx-point');
      expect(c.emotes[1].soundDelayTicks, 3);

      expect(c.emotes[2].modifier, EmoteModifier.zoom);
      expect(c.emotes[2].deskMod, isNull);
      expect(c.emotes[2].hasDeskField, isFalse);

      expect(c.frameEffects.length, 1);
      expect(c.frameEffects.first.spriteRef, '(b)point');
      expect(c.frameEffects.first.kind, FrameEffectKind.sfx);
    });

    test('emote lines round-trip exactly (4-field, trailing-#, and 5-field)', () {
      final Character c = Character.parse(_sample);
      expect(c.emotes[0].toLine(), 'Normal#-#normal#0#');
      expect(c.emotes[1].toLine(), 'Point#point_pre#point#1#1');
      expect(c.emotes[2].toLine(), 'Zoom#-#zoom#5');
    });

    test('serialize -> parse is stable (idempotent)', () {
      final Character a = Character.parse(_sample);
      final Character b = Character.parse(a.serialize());
      expect(b.serialize(), a.serialize());
      expect(b.emotes.length, 3);
      expect(b.frameEffects.length, 1);
      expect(b.emotes[1].soundName, 'sfx-point');
    });

    test('gender is modernised into blips', () {
      final Character c = Character.parse('[Options]\nname = g\ngender = female\n');
      expect(c.options.blips, 'female');
    });
  });
}
