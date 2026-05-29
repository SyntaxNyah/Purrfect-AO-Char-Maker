import 'package:flutter_test/flutter_test.dart';
import 'package:purrfect/src/discovery/bulk_rename.dart';

void main() {
  test('find/replace', () {
    const RenameSpec s = RenameSpec(find: '_', replace: ' ');
    expect(BulkRename.newName('upset_look', 0, s), 'upset look');
  });

  test('prefix + suffix', () {
    const RenameSpec s = RenameSpec(prefix: 'Niko ', suffix: '!');
    expect(BulkRename.newName('Happy', 0, s), 'Niko Happy!');
  });

  test('sequential template', () {
    const RenameSpec s =
        RenameSpec(sequential: true, sequentialTemplate: 'Emote {n}');
    expect(BulkRename.newName('whatever', 4, s), 'Emote 5');
    const RenameSpec s2 =
        RenameSpec(sequential: true, sequentialTemplate: '{name} #{n}');
    expect(BulkRename.newName('Smile', 0, s2), 'Smile #1');
  });

  test('case modes', () {
    expect(BulkRename.newName('hello world', 0, const RenameSpec(caseMode: RenameCase.title)),
        'Hello World');
    expect(BulkRename.newName('Hello', 0, const RenameSpec(caseMode: RenameCase.upper)), 'HELLO');
    expect(BulkRename.newName('Hello', 0, const RenameSpec(caseMode: RenameCase.lower)), 'hello');
  });

  test('isNoop', () {
    expect(const RenameSpec().isNoop, isTrue);
    expect(const RenameSpec(prefix: 'x').isNoop, isFalse);
  });
}
