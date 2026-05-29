import 'workspace.dart';

/// On the web there is no ambient filesystem, so a "local" workspace is an
/// in-memory one hydrated from the files the user drops / imports, and exported
/// back out as a downloadable `.zip`.
Workspace createLocalWorkspace(String root) => MemoryWorkspace(root: root);
