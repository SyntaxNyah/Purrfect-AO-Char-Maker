import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'workspace.dart';

/// Real-filesystem workspace for Windows / Linux / macOS / Android / iOS.
class IoWorkspace implements Workspace {
  IoWorkspace(this._root);

  final String _root;

  @override
  String get root => _root;

  String _abs(String rel) => p.normalize(p.join(_root, Workspace.norm(rel)));

  @override
  Future<List<String>> listFiles({bool recursive = true}) async {
    final Directory dir = Directory(_root);
    if (!dir.existsSync()) return <String>[];
    final List<String> out = <String>[];
    await for (final FileSystemEntity ent in dir.list(recursive: recursive)) {
      if (ent is File) {
        out.add(p.relative(ent.path, from: _root).replaceAll(r'\', '/'));
      }
    }
    out.sort();
    return out;
  }

  @override
  Future<bool> exists(String rel) => File(_abs(rel)).exists();

  @override
  Future<Uint8List> readBytes(String rel) => File(_abs(rel)).readAsBytes();

  @override
  Future<String> readString(String rel) => File(_abs(rel)).readAsString();

  @override
  Future<void> writeBytes(String rel, List<int> data) async {
    final File f = File(_abs(rel));
    await f.parent.create(recursive: true);
    await f.writeAsBytes(data);
  }

  @override
  Future<void> writeString(String rel, String data) async {
    final File f = File(_abs(rel));
    await f.parent.create(recursive: true);
    await f.writeAsString(data);
  }

  @override
  Future<void> makeDir(String rel) async =>
      Directory(_abs(rel)).create(recursive: true);

  @override
  Future<void> copy(String fromRel, String toRel) async {
    final File dst = File(_abs(toRel));
    await dst.parent.create(recursive: true);
    await File(_abs(fromRel)).copy(dst.path);
  }

  @override
  Future<void> move(String fromRel, String toRel) async {
    final File src = File(_abs(fromRel));
    final File dst = File(_abs(toRel));
    await dst.parent.create(recursive: true);
    try {
      await src.rename(dst.path);
    } on FileSystemException {
      // Cross-device rename — fall back to copy+delete.
      await src.copy(dst.path);
      await src.delete();
    }
  }

  @override
  Future<void> delete(String rel) async {
    final File f = File(_abs(rel));
    if (await f.exists()) await f.delete();
  }
}

/// Platform factory (selected via conditional import in workspace_factory.dart).
Workspace createLocalWorkspace(String root) => IoWorkspace(root);
