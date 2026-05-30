import 'package:flutter_test/flutter_test.dart';
import 'package:pinsel/src/discovery/character_builder.dart';
import 'package:pinsel/src/discovery/sprite_scanner.dart';
import 'package:pinsel/src/core/ao_constants.dart';

void main() {
  const SpriteScanner scanner = SpriteScanner();

  test('classifies (a)/(b) pairs, statics, subfolders, preanims, ignores', () {
    final ScanResult r = scanner.fromPaths(<String>[
      '(a)happy.png',
      '(b)happy.png',
      'normal.png',
      '(a)/def/think.webp',
      '(b)/def/think.webp',
      'anim/wave.gif',
      'char_icon.png',
      'emotions/button1_off.png',
    ]);

    final Map<String, SpriteGroup> byBase = <String, SpriteGroup>{
      for (final SpriteGroup g in r.groups) g.base: g,
    };

    expect(byBase.containsKey('happy'), isTrue);
    expect(byBase['happy']!.idle, isNotNull);
    expect(byBase['happy']!.talk, isNotNull);

    expect(byBase.containsKey('normal'), isTrue);
    expect(byBase['normal']!.hasStatic, isTrue);

    expect(byBase.containsKey('/def/think'), isTrue);
    expect(byBase['/def/think']!.idle, isNotNull);

    expect(r.preanimCandidates.any((SpriteFile f) => f.relPath == 'anim/wave.gif'),
        isTrue);
    expect(r.ignored.contains('char_icon.png'), isTrue);
    expect(r.ignored.any((String p) => p.startsWith('emotions/')), isTrue);
  });

  test('extension priority prefers webp over png for same sprite/state', () {
    final ScanResult r = scanner.fromPaths(<String>['(a)x.png', '(a)x.webp']);
    final SpriteGroup g = r.groups.single;
    expect(g.idle!.ext, 'webp');
  });

  test('auto-builder produces emotes with sensible defaults', () {
    final ScanResult r = scanner.fromPaths(<String>[
      '(a)normal.png', '(b)normal.png',
      '(a)point.png', '(b)point.png', 'point.png', // bare => preanim
      'document.png',
    ]);
    final c = const CharacterBuilder().build(r, config: const BuildConfig(name: 'bob'));
    expect(c.options.name, 'bob');
    expect(c.emotes.length, 3);
    // "normal" floats to the front via preferredFirstNames.
    expect(c.emotes.first.sprite, 'normal');
    final point = c.emotes.firstWhere((e) => e.sprite == 'point');
    expect(point.modifier, EmoteModifier.preanim);
    expect(point.preanim, 'point');
  });
}
