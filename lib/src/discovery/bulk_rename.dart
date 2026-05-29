/// How to transform a name's casing in a bulk rename.
enum RenameCase { keep, lower, upper, title }

/// A reusable bulk-rename recipe applied to emote names (and optionally sprite
/// names/files). Steps run in this order: find/replace → sequential template →
/// prefix/suffix → case.
class RenameSpec {
  const RenameSpec({
    this.find = '',
    this.replace = '',
    this.regex = false,
    this.prefix = '',
    this.suffix = '',
    this.sequential = false,
    this.sequentialTemplate = 'Emote {n}',
    this.caseMode = RenameCase.keep,
    this.renameSprites = false,
  });

  final String find;
  final String replace;
  final bool regex;
  final String prefix;
  final String suffix;

  /// Replace the whole name with [sequentialTemplate] (`{n}` = 1-based index,
  /// `{name}` = current name).
  final bool sequential;
  final String sequentialTemplate;

  final RenameCase caseMode;

  /// Also rename the emote's sprite + its files on disk (root sprites only).
  final bool renameSprites;

  bool get isNoop =>
      find.isEmpty &&
      prefix.isEmpty &&
      suffix.isEmpty &&
      !sequential &&
      caseMode == RenameCase.keep;
}

/// Pure name transformer (no I/O) — easy to unit test.
class BulkRename {
  const BulkRename._();

  /// Compute the new name for [oldName] at 0-based [index] under [spec].
  static String newName(String oldName, int index, RenameSpec spec) {
    String s = oldName;
    if (spec.find.isNotEmpty) {
      s = spec.regex
          ? s.replaceAll(RegExp(spec.find), spec.replace)
          : s.replaceAll(spec.find, spec.replace);
    }
    if (spec.sequential) {
      s = spec.sequentialTemplate
          .replaceAll('{n}', '${index + 1}')
          .replaceAll('{name}', s);
    }
    s = '${spec.prefix}$s${spec.suffix}';
    switch (spec.caseMode) {
      case RenameCase.keep:
        break;
      case RenameCase.lower:
        s = s.toLowerCase();
      case RenameCase.upper:
        s = s.toUpperCase();
      case RenameCase.title:
        s = s
            .split(RegExp(r'(\s+)'))
            .map((String w) =>
                w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
    }
    return s.trim();
  }
}
