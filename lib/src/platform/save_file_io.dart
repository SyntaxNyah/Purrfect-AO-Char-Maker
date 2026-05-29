import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Native save: ask the user where to put the file, then write it.
Future<String?> saveBytes(String suggestedName, Uint8List bytes) async {
  final String? path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save',
    fileName: suggestedName,
    bytes: bytes,
  );
  if (path == null) return null;
  // On some platforms saveFile already writes via `bytes:`; ensure it exists.
  final File f = File(path);
  if (!await f.exists()) {
    await f.writeAsBytes(bytes);
  }
  return path;
}
