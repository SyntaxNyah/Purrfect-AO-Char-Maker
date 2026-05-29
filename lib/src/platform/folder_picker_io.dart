import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

Future<List<({String name, Uint8List bytes})>?> pickFolderFiles() async {
  final String? dir = await FilePicker.platform.getDirectoryPath();
  if (dir == null) return null;
  final List<({String name, Uint8List bytes})> out =
      <({String name, Uint8List bytes})>[];
  await for (final FileSystemEntity ent in Directory(dir).list(recursive: true)) {
    if (ent is File) {
      final String rel = p.relative(ent.path, from: dir).replaceAll(r'\', '/');
      out.add((name: rel, bytes: await ent.readAsBytes()));
    }
  }
  return out;
}
