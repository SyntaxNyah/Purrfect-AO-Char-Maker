import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../animation/anim_clip.dart';
import '../animation/anim_engine.dart';
import '../core/ao_constants.dart';
import '../core/character.dart';
import '../core/emote.dart';
import '../core/history.dart';
import '../core/validator.dart';
import '../discovery/character_builder.dart';
import '../discovery/organizer.dart';
import '../discovery/sprite_scanner.dart';
import '../imaging/bulk_processor.dart';
import '../imaging/button_maker.dart';
import '../imaging/codecs.dart';
import '../imaging/color_ops.dart';
import '../platform/save_file.dart';
import '../platform/workspace.dart';

/// A file handed to the app by a picker (name + bytes), platform-neutral.
class PickedFile {
  PickedFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// The single source of UI truth. Holds the working project (an in-memory
/// workspace so behaviour is identical on every platform), the parsed/auto-built
/// [Character], undo/redo, the live colour pipeline, and all the actions the
/// screens trigger.
class AppState extends ChangeNotifier {
  final MemoryWorkspace workspace = MemoryWorkspace();
  final EditHistory history = EditHistory();
  final SpriteScanner _scanner = const SpriteScanner();

  ScanResult? scan;
  Character? character;
  BuildConfig buildConfig = const BuildConfig();

  int selectedEmote = -1;
  String status = 'Import a folder of sprites to begin.';
  bool busy = false;

  /// The live colour-op pipeline edited in the Colour Lab.
  final List<ColorOp> livePipeline = <ColorOp>[];

  /// Decoded first-frame cache (rel -> image) to keep previews snappy.
  final Map<String, img.Image?> _decodeCache = <String, img.Image?>{};

  bool get hasProject => character != null;

  List<LintIssue> get issues => character == null
      ? const <LintIssue>[]
      : CharacterValidator.validate(character!, scan: scan);

  // ---------------------------------------------------------------------------
  // Importing
  // ---------------------------------------------------------------------------

  Future<void> importFiles(List<PickedFile> files) async {
    _setBusy(true, 'Importing ${files.length} files…');
    for (final PickedFile f in files) {
      workspace.put(f.name, f.bytes);
    }
    await _rebuild();
    _setBusy(false, 'Imported ${files.length} files.');
  }

  /// Pull every file from an external workspace (e.g. a real directory) into the
  /// in-memory project.
  Future<void> importWorkspace(Workspace external) async {
    _setBusy(true, 'Importing folder…');
    final List<String> files = await external.listFiles();
    for (final String rel in files) {
      workspace.put(rel, await external.readBytes(rel));
    }
    await _rebuild();
    _setBusy(false, 'Imported ${files.length} files.');
  }

  Future<void> _rebuild() async {
    _decodeCache.clear();
    final List<String> files = await workspace.listFiles();
    scan = _scanner.fromPaths(files);

    // If an existing char.ini is present, honour it; otherwise auto-build.
    final String? iniRel = files.firstWhereOrNull(
        (String f) => p.basename(f).toLowerCase() == CharFolder.iniName);
    if (iniRel != null) {
      character = Character.parse(await workspace.readString(iniRel));
      status = 'Loaded existing ${CharFolder.iniName} '
          '(${character!.emotes.length} emotes).';
    } else {
      character = const CharacterBuilder().build(scan!, config: buildConfig);
      status = 'Auto-built ${character!.emotes.length} emotes from sprites.';
    }
    history.seed(character!);
    selectedEmote = character!.emotes.isEmpty ? -1 : 0;
  }

  void updateBuildConfig(BuildConfig c) {
    buildConfig = c;
    notifyListeners();
  }

  /// Re-run the auto-builder with the current [buildConfig] (discards manual
  /// emote edits — used from the "regenerate" action).
  Future<void> regenerate() async {
    if (scan == null) return;
    character = const CharacterBuilder().build(scan!, config: buildConfig);
    history.seed(character!);
    selectedEmote = character!.emotes.isEmpty ? -1 : 0;
    status = 'Regenerated ${character!.emotes.length} emotes.';
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Editing
  // ---------------------------------------------------------------------------

  Emote? get current =>
      (character != null && selectedEmote >= 0 && selectedEmote < character!.emotes.length)
          ? character!.emotes[selectedEmote]
          : null;

  void selectEmote(int index) {
    selectedEmote = index;
    notifyListeners();
  }

  /// Notify listeners without recording an undo step (live typing).
  void touch() => notifyListeners();

  void commitEdit() {
    if (character != null) history.push(character!);
    notifyListeners();
  }

  void addEmote() {
    if (character == null) return;
    character!.emotes.add(Emote(comment: 'New', deskMod: DeskModifier.show));
    selectedEmote = character!.emotes.length - 1;
    commitEdit();
  }

  void deleteEmote(int index) {
    if (character == null || index < 0 || index >= character!.emotes.length) return;
    character!.emotes.removeAt(index);
    selectedEmote = character!.emotes.isEmpty
        ? -1
        : index.clamp(0, character!.emotes.length - 1);
    commitEdit();
  }

  void moveEmote(int from, int to) {
    if (character == null) return;
    final List<Emote> e = character!.emotes;
    if (from < 0 || from >= e.length || to < 0 || to >= e.length) return;
    e.insert(to, e.removeAt(from));
    selectedEmote = to;
    commitEdit();
  }

  void undo() {
    final Character? c = history.undo();
    if (c != null) {
      character = c;
      selectedEmote = selectedEmote.clamp(-1, c.emotes.length - 1);
      notifyListeners();
    }
  }

  void redo() {
    final Character? c = history.redo();
    if (c != null) {
      character = c;
      selectedEmote = selectedEmote.clamp(-1, c.emotes.length - 1);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Sprite resolution + previews
  // ---------------------------------------------------------------------------

  /// The representative sprite file (rel path) for an emote, if discovered.
  String? spriteRelFor(Emote e) {
    final SpriteGroup? g =
        scan?.groups.firstWhereOrNull((SpriteGroup g) => g.base == e.sprite);
    return g?.representative?.relPath;
  }

  Future<img.Image?> decodeFirstFrame(String rel) async {
    if (_decodeCache.containsKey(rel)) return _decodeCache[rel];
    img.Image? image;
    if (await workspace.exists(rel)) {
      final Uint8List bytes = await workspace.readBytes(rel);
      image = Codecs.decodeFirstFrame(bytes, ext: p.extension(rel).replaceFirst('.', ''));
    }
    _decodeCache[rel] = image;
    return image;
  }

  /// PNG bytes of [rel] with [pipeline] applied to a downscaled copy — used for
  /// the real-time Colour Lab preview.
  Future<Uint8List?> previewWithPipeline(String rel, List<ColorOp> pipeline,
      {int maxEdge = 640}) async {
    final img.Image? src = await decodeFirstFrame(rel);
    if (src == null) return null;
    img.Image work = src.clone();
    final int longest = work.width > work.height ? work.width : work.height;
    if (longest > maxEdge) {
      final double s = maxEdge / longest;
      // Use a good downscale filter so the preview isn't pixelated.
      work = img.copyResize(work,
          width: (work.width * s).round(),
          height: (work.height * s).round(),
          interpolation: img.Interpolation.average);
    }
    if (pipeline.isNotEmpty) ImageOps.applyAll(work, pipeline);
    return Codecs.encodePng(work);
  }

  /// Sprite base names available for mixing/compositing.
  List<String> spriteBases() =>
      (scan?.groups ?? <SpriteGroup>[]).map((SpriteGroup g) => g.base).toList();

  String? relForBase(String base) => scan?.groups
      .firstWhereOrNull((SpriteGroup g) => g.base == base)
      ?.representative
      ?.relPath;

  /// Save a freshly composited image as a brand-new static sprite + emote, so
  /// "head-on-body" creations become first-class emotes in the project.
  Future<void> addCompositeSprite(String name, Uint8List png) async {
    final String safe = name.trim().isEmpty ? 'mix' : name.trim();
    final String rel = '$safe.png';
    await workspace.writeBytes(rel, png);
    _decodeCache.remove(rel);

    // Register it with the scan so previews/buttons resolve it.
    final SpriteGroup group = SpriteGroup(safe)
      ..statics.add(SpriteFile(
        relPath: rel,
        ext: 'png',
        state: SpriteState.staticImage,
        base: safe,
      ));
    scan?.groups.add(group);

    character?.emotes.add(Emote(comment: safe, sprite: safe, deskMod: DeskModifier.show));
    selectedEmote = (character?.emotes.length ?? 1) - 1;
    commitEdit();
    status = 'Added composite sprite "$safe".';
  }

  // ---------------------------------------------------------------------------
  // Colour pipeline editing
  // ---------------------------------------------------------------------------

  void setLivePipeline(List<ColorOp> ops) {
    livePipeline
      ..clear()
      ..addAll(ops);
    notifyListeners();
  }

  void addLiveOp(ColorOp op) {
    livePipeline.add(op);
    notifyListeners();
  }

  void clearLivePipeline() {
    livePipeline.clear();
    notifyListeners();
  }

  /// Bake the live pipeline into one or all sprites in the project.
  Future<int> applyPipeline({required bool allSprites}) async {
    if (livePipeline.isEmpty) return 0;
    _setBusy(true, 'Applying colour pipeline…');
    final List<String> targets = <String>[];
    if (allSprites) {
      for (final SpriteGroup g in scan?.groups ?? <SpriteGroup>[]) {
        for (final SpriteFile f in <SpriteFile?>[g.idle, g.talk, g.post, ...g.statics]
            .whereType<SpriteFile>()) {
          targets.add(f.relPath);
        }
      }
    } else if (current != null) {
      final String? rel = spriteRelFor(current!);
      if (rel != null) targets.add(rel);
    }
    final BulkProcessor proc = BulkProcessor(workspace);
    final List<BulkResult> res = await proc.run(
      files: targets,
      pipeline: livePipeline,
      onProgress: (int d, int t, String l) => _progress(d, t, 'Recolour'),
    );
    _decodeCache.clear();
    final int ok = res.where((BulkResult r) => r.ok).length;
    _setBusy(false, 'Recoloured $ok sprite(s).');
    return ok;
  }

  /// Preview the auto-generated button for the selected emote at [size] px.
  Future<Uint8List?> previewAutoButton(int size) async {
    final Emote? e = current;
    if (e == null) return null;
    final String? rel = spriteRelFor(e);
    if (rel == null) return null;
    final Uint8List bytes = await workspace.readBytes(rel);
    return ButtonMaker.renderAuto(bytes, p.extension(rel).replaceFirst('.', ''), size);
  }

  /// Convert every sprite to [format] (with optional WebP settings).
  Future<int> bulkConvert(
    OutputFormat format, {
    bool webpLossless = false,
    int webpQuality = 90,
    bool deleteOriginal = false,
  }) async {
    if (scan == null) return 0;
    _setBusy(true, 'Converting sprites…');
    final List<String> targets = <String>[];
    for (final SpriteGroup g in scan!.groups) {
      for (final SpriteFile f
          in <SpriteFile?>[g.idle, g.talk, g.post, ...g.statics].whereType<SpriteFile>()) {
        targets.add(f.relPath);
      }
    }
    final List<BulkResult> res = await BulkProcessor(workspace).run(
      files: targets,
      output: format,
      webpLossless: webpLossless,
      webpQuality: webpQuality,
      deleteOriginalOnConvert: deleteOriginal,
      onProgress: (int d, int t, String l) => _progress(d, t, 'Convert'),
    );
    _decodeCache.clear();
    if (deleteOriginal) await _rebuild();
    final int ok = res.where((BulkResult r) => r.ok).length;
    final int fail = res.length - ok;
    _setBusy(false, 'Converted $ok sprite(s)${fail > 0 ? ', $fail failed' : ''}.');
    return ok;
  }

  // ---------------------------------------------------------------------------
  // Animation generation
  // ---------------------------------------------------------------------------

  /// Render a preview clip for the selected sprite using [recipes].
  Future<List<Uint8List>> renderAnimationPreview(
    List<AnimRecipe> recipes, {
    int frames = 12,
    int fps = 12,
  }) async {
    final Emote? e = current;
    if (e == null) return <Uint8List>[];
    final String? rel = spriteRelFor(e);
    if (rel == null) return <Uint8List>[];
    final img.Image? base = await decodeFirstFrame(rel);
    if (base == null) return <Uint8List>[];
    final AnimClip clip = AnimEngine.render(base, recipes, frames: frames, fps: fps);
    return clip.frames.map((AnimFrame f) => Codecs.encodePng(f.image)).toList();
  }

  /// Render an animation onto the selected sprite at full resolution and save it
  /// (e.g. as a talking `(b)` sprite) as an APNG/GIF.
  Future<String?> saveAnimation(
    List<AnimRecipe> recipes, {
    int frames = 12,
    int fps = 12,
    String prefix = SpritePrefix.talk,
    // WebP is the default. Lossless by default so quality is preserved. Falls
    // back to APNG only if the platform genuinely can't encode WebP.
    bool preferWebp = true,
    bool lossless = true,
    int quality = 95,
  }) async {
    final Emote? e = current;
    if (e == null) return null;
    final String? rel = spriteRelFor(e);
    if (rel == null) return null;
    final img.Image? base = await decodeFirstFrame(rel);
    if (base == null) return null;
    _setBusy(true, 'Rendering animation…');
    final AnimClip clip = AnimEngine.render(base, recipes, frames: frames, fps: fps);

    final Uint8List bytes;
    final String ext;
    if (preferWebp) {
      final ({Uint8List bytes, String ext}) r =
          await clip.encodePreferWebp(lossless: lossless, quality: quality);
      bytes = r.bytes;
      ext = r.ext;
    } else {
      bytes = clip.encode(ext: 'apng');
      ext = 'apng';
    }

    // Also drop it into the project so it becomes part of the export.
    final String spriteName = e.sprite.isEmpty ? 'anim' : e.sprite;
    final String outRel = '$prefix$spriteName.$ext';
    await workspace.writeBytes(outRel, bytes);
    _decodeCache.clear();
    final String note = ext == 'webp'
        ? 'WebP'
        : 'APNG (WebP encoder not found here — release builds ship with it)';
    _setBusy(false, 'Saved $outRel as $note.');
    return saveBytes('$prefix$spriteName.$ext', bytes);
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Organise into a tidy character folder (with auto buttons + ini) and return
  /// the resulting in-memory workspace.
  Future<MemoryWorkspace> buildOutput() async {
    final MemoryWorkspace out = MemoryWorkspace();
    if (character == null || scan == null) return out;
    final Organizer organizer = Organizer(buttonRenderer: ButtonMaker.renderAuto);
    await organizer.organize(
      character: character!,
      scan: scan!,
      source: workspace,
      target: out,
      config: OrganizeConfig(targetCharDir: character!.options.name),
      onProgress: (int d, int t, String l) => _progress(d, t, l),
    );
    return out;
  }

  /// Build the character and download/save it as a `.zip` ready to drop into AO.
  Future<String?> exportZip() async {
    _setBusy(true, 'Building character…');
    final MemoryWorkspace out = await buildOutput();
    final Archive archive = Archive();
    out.snapshot.forEach((String rel, Uint8List bytes) {
      archive.addFile(ArchiveFile(rel, bytes.length, bytes));
    });
    final List<int>? zip = ZipEncoder().encode(archive);
    _setBusy(false, 'Character built.');
    if (zip == null) return null;
    final String name = '${character?.options.name ?? 'character'}.zip';
    return saveBytes(name, Uint8List.fromList(zip));
  }

  /// Save just the char.ini.
  Future<String?> exportIni() async {
    if (character == null) return null;
    final Uint8List bytes = Uint8List.fromList(character!.serialize().codeUnits);
    return saveBytes(CharFolder.iniName, bytes);
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------

  void _setBusy(bool b, String msg) {
    busy = b;
    status = msg;
    notifyListeners();
  }

  void _progress(int done, int total, String label) {
    status = '$label  $done/$total';
    notifyListeners();
  }
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final E e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
