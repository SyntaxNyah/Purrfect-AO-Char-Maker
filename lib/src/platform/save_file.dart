import 'dart:typed_data';

import 'save_file_io.dart' if (dart.library.html) 'save_file_web.dart' as impl;

/// Save/download [bytes] under [suggestedName].
///
///  * Native: opens a save dialog (or writes to a chosen path).
///  * Web: triggers a browser download.
///
/// Returns the path written (native) or the file name (web), or null if the
/// user cancelled.
Future<String?> saveBytes(String suggestedName, Uint8List bytes) =>
    impl.saveBytes(suggestedName, bytes);
