import 'dart:typed_data';

import 'folder_picker_io.dart'
    if (dart.library.html) 'folder_picker_web.dart' as impl;

/// A file picked as part of a folder selection: [name] is the path relative to
/// the chosen folder (using `/`), so sub-folder structure is preserved.
typedef PickedFolderFile = ({String name, Uint8List bytes});

/// Let the user pick a whole **folder** of sprites (recursively), on every
/// platform:
///  * desktop/mobile — native directory picker;
///  * web — a `<input webkitdirectory>` folder upload.
/// Returns null if cancelled.
Future<List<PickedFolderFile>?> pickFolderFiles() => impl.pickFolderFiles();
