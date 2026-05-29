// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<List<({String name, Uint8List bytes})>?> pickFolderFiles() async {
  final html.FileUploadInputElement input = html.FileUploadInputElement()
    ..multiple = true
    ..accept = 'image/*';
  // Folder upload (Chromium/WebKit). Falls back to multi-file elsewhere.
  input.setAttribute('webkitdirectory', '');
  input.setAttribute('directory', '');
  input.style.display = 'none';
  html.document.body?.append(input);
  input.click();
  await input.onChange.first;
  final List<html.File>? files = input.files;
  input.remove();
  if (files == null || files.isEmpty) return null;

  final List<({String name, Uint8List bytes})> out =
      <({String name, Uint8List bytes})>[];
  for (final html.File f in files) {
    final html.FileReader reader = html.FileReader();
    reader.readAsArrayBuffer(f);
    await reader.onLoad.first;
    final Object? result = reader.result;
    final Uint8List bytes = result is ByteBuffer
        ? result.asUint8List()
        : Uint8List.fromList(result as List<int>);
    // `relativePath` carries the folder structure (e.g. MyChar/(a)happy.png).
    final String rel =
        (f.relativePath != null && f.relativePath!.isNotEmpty) ? f.relativePath! : f.name;
    out.add((name: rel, bytes: bytes));
  }
  return out;
}
