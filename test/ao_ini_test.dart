import 'package:flutter_test/flutter_test.dart';
import 'package:purrfect/src/core/ao_ini.dart';

void main() {
  group('IniDocument', () {
    test('parses sections and key/value pairs', () {
      final IniDocument doc = IniDocument.parse('''
[Options]
name = phoenix
side = def

[Emotions]
number = 1
1 = Normal#-#normal#0#
''');
      expect(doc.section('options')?.value('name'), 'phoenix');
      expect(doc.section('OPTIONS')?.value('SIDE'), 'def'); // case-insensitive
      expect(doc.section('emotions')?.value('1'), 'Normal#-#normal#0#');
    });

    test('keeps # inside values (emote separator) but drops leading comments', () {
      final IniDocument doc = IniDocument.parse('''
# a comment
[Emotions]
1 = A#b#c#0#1
''');
      expect(doc.section('emotions')?.value('1'), 'A#b#c#0#1');
    });

    test('repairs mangled run-on numeric lines', () {
      final IniDocument doc = IniDocument.parse('''
[SoundN]
1  = 02  = 03  = 0
''');
      final IniSectionData s = doc.section('soundn')!;
      expect(s.value('1'), '0');
      expect(s.value('2'), '0');
      expect(s.value('3'), '0');
    });

    test('repairs run-on with a non-numeric value glued to next key', () {
      final IniDocument doc = IniDocument.parse('''
[SoundN]
9  = sfx-deskslam10 = 0
''');
      final IniSectionData s = doc.section('soundn')!;
      expect(s.value('9'), 'sfx-deskslam');
      expect(s.value('10'), '0');
    });

    test('round-trips through serialize', () {
      const String text = '[Options]\nname = x\n\n[Emotions]\nnumber = 1\n1 = N#-#n#0#\n';
      final IniDocument a = IniDocument.parse(text);
      final IniDocument b = IniDocument.parse(a.serialize());
      expect(b.section('options')?.value('name'), 'x');
      expect(b.section('emotions')?.value('1'), 'N#-#n#0#');
    });
  });
}
