// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Web save: create an in-memory blob and click a download link.
Future<String?> saveBytes(String suggestedName, Uint8List bytes) async {
  final html.Blob blob = html.Blob(<Object>[bytes]);
  final String url = html.Url.createObjectUrlFromBlob(blob);
  final html.AnchorElement anchor = html.AnchorElement(href: url)
    ..download = suggestedName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return suggestedName;
}
