/// Re-exports the correct [createLocalWorkspace] for the current platform:
///  * native (dart:io)  -> IoWorkspace
///  * web   (dart:html) -> in-memory MemoryWorkspace
///
/// Import this file (never io_workspace/web_workspace directly) so the app keeps
/// compiling for every target.
library;

export 'workspace.dart';
export 'io_workspace.dart' if (dart.library.html) 'web_workspace.dart';
