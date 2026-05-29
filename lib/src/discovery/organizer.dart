import 'dart:typed_data';

import '../core/ao_constants.dart';
import '../core/character.dart';
import '../core/emote.dart';
import '../platform/workspace.dart';
import 'sprite_scanner.dart';

/// Renders a square button icon from a source image's first frame.
/// Returns null if it cannot produce one. Injected from the imaging layer so
/// the organiser has no hard dependency on the image engine.
typedef ButtonRenderer = Future<Uint8List?> Function(
  Uint8List sourceBytes,
  String ext,
  int size,
);

/// Progress callback: (completed, total, label).
typedef ProgressCallback = void Function(int done, int total, String label);

/// Options for an organise/export run.
class OrganizeConfig {
  const OrganizeConfig({
    this.targetCharDir,
    this.deleteOriginals = false,
    this.generateButtons = true,
    this.buttonSize = CharFolder.defaultButtonSize,
    this.overwriteExistingButtons = false,
  });

  /// Where the character folder goes inside the target workspace. Defaults to
  /// the character's `name`.
  final String? targetCharDir;

  /// Move (delete source after copy) instead of copy. Only honoured when source
  /// and target are the same workspace.
  final bool deleteOriginals;

  final bool generateButtons;
  final int buttonSize;
  final bool overwriteExistingButtons;
}

/// A single planned file relocation.
class FileOp {
  FileOp(this.fromRel, this.toRel);
  final String fromRel;
  final String toRel;
}

/// A single planned button to render.
class ButtonJob {
  ButtonJob({
    required this.emoteIndex,
    required this.sourceRel,
    required this.targetRel,
  });
  final int emoteIndex; // 0-based
  final String sourceRel; // within target workspace, after files are copied
  final String targetRel;
}

/// The full, inspectable plan produced before anything touches the workspace.
class OrganizePlan {
  OrganizePlan(this.charDir);
  final String charDir;
  final List<FileOp> fileOps = <FileOp>[];
  final List<ButtonJob> buttonJobs = <ButtonJob>[];
  late String iniRel;
  String? iniText;
}

/// Builds and executes a plan that turns scanned sprites + a built [Character]
/// into a tidy, AO-ready character folder.
class Organizer {
  const Organizer({this.buttonRenderer});

  final ButtonRenderer? buttonRenderer;

  /// Compute the plan without performing any writes.
  OrganizePlan plan({
    required Character character,
    required ScanResult scan,
    required List<String> sourceFiles,
    OrganizeConfig config = const OrganizeConfig(),
  }) {
    final String charDir =
        Workspace.norm(config.targetCharDir ?? character.options.name);
    final OrganizePlan plan = OrganizePlan(charDir);

    // Copy every source file into the character folder, preserving structure.
    for (final String rel in sourceFiles) {
      plan.fileOps.add(FileOp(rel, joinRel(charDir, rel)));
    }

    plan.iniRel = joinRel(charDir, CharFolder.iniName);
    plan.iniText = character.serialize();

    if (config.generateButtons) {
      final Map<String, SpriteGroup> byBase = <String, SpriteGroup>{
        for (final SpriteGroup g in scan.groups) g.base: g,
      };
      for (int i = 0; i < character.emotes.length; i++) {
        final Emote e = character.emotes[i];
        final SpriteGroup? g = byBase[e.sprite];
        final SpriteFile? rep = g?.representative;
        if (rep == null) continue;
        plan.buttonJobs.add(ButtonJob(
          emoteIndex: i,
          sourceRel: joinRel(charDir, rep.relPath),
          targetRel: joinRel(
            charDir,
            '${CharFolder.emotionsDir}/${CharFolder.buttonName(i + 1, on: false)}',
          ),
        ));
      }
    }
    return plan;
  }

  /// Execute a [plan]: copy/move files, write the ini, and render buttons.
  Future<void> execute(
    OrganizePlan plan, {
    required Workspace source,
    required Workspace target,
    OrganizeConfig config = const OrganizeConfig(),
    ProgressCallback? onProgress,
  }) async {
    final bool sameWs = identical(source, target);
    final int total = plan.fileOps.length +
        1 /* ini */ +
        plan.buttonJobs.length;
    int done = 0;
    void tick(String label) => onProgress?.call(++done, total, label);

    for (final FileOp op in plan.fileOps) {
      final Uint8List bytes = await source.readBytes(op.fromRel);
      await target.writeBytes(op.toRel, bytes);
      if (config.deleteOriginals && sameWs && op.fromRel != op.toRel) {
        await source.delete(op.fromRel);
      }
      tick('Copied ${op.toRel}');
    }

    await target.writeString(plan.iniRel, plan.iniText ?? '');
    tick('Wrote ${plan.iniRel}');

    if (buttonRenderer != null) {
      for (final ButtonJob job in plan.buttonJobs) {
        if (!config.overwriteExistingButtons &&
            await target.exists(job.targetRel)) {
          tick('Kept existing ${job.targetRel}');
          continue;
        }
        final Uint8List src = await target.readBytes(job.sourceRel);
        final String ext = job.sourceRel.split('.').last.toLowerCase();
        final Uint8List? png =
            await buttonRenderer!(src, ext, config.buttonSize);
        if (png != null) {
          await target.writeBytes(job.targetRel, png);
        }
        tick('Button ${job.emoteIndex + 1}');
      }
    }
  }

  /// One-shot convenience: plan + execute.
  Future<OrganizePlan> organize({
    required Character character,
    required ScanResult scan,
    required Workspace source,
    required Workspace target,
    OrganizeConfig config = const OrganizeConfig(),
    ProgressCallback? onProgress,
  }) async {
    final List<String> files = await source.listFiles();
    final OrganizePlan p = plan(
      character: character,
      scan: scan,
      sourceFiles: files,
      config: config,
    );
    await execute(p,
        source: source, target: target, config: config, onProgress: onProgress);
    return p;
  }
}
