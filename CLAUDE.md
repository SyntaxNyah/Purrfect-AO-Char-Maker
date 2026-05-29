# CLAUDE.md — developer guide for the Purrfect AO Char Maker

This file is the working manual for anyone (especially Claude) building features
in this repo. It explains the principles, the build, **every module and its
public functions**, the gotchas, and step-by-step "how to add X" recipes.

> If you're a user, read [README.md](README.md) instead. This is the dev guide.

---

## 0. Principles (follow these)

1. **Engine vs UI split.** Everything under `lib/src/{core,discovery,imaging,
   animation,presets,plugins,platform}` is **pure Dart with no `package:flutter`
   import** (platform files may use `dart:io`/`dart:html`/`dart:ffi` behind
   conditional imports). Only `lib/src/ui/**` and `lib/main.dart` import Flutter.
   Keep it that way so the engine stays testable and identical on every target.
2. **No magic numbers / strings.** AO constants live in
   `lib/src/core/ao_constants.dart`. Add new ones there; don't inline them.
3. **One model, many features.** Recolour = `ColorOp`/`OpPipeline`. Animation =
   `AnimRecipe`. Both serialise to JSON so they power preview, bulk, presets and
   plugins at once. Prefer adding to these over bespoke code paths.
4. **Lossless & tolerant.** The `char.ini` reader preserves unknown data and
   repairs malformed input. Never drop data on a round-trip.
5. **Graceful platform fallback.** WebP is the default output but must fall back
   to APNG/PNG when a platform can't encode it. Never hard-fail because an
   optional native lib is missing.
6. **Document new public APIs** with `///` doc comments, and update the relevant
   `docs/*.md` + `ROADMAP.md`.

---

## 1. Build / run / test

Flutter 3.22+ (Dart 3.4+). Platform folders are gitignored and regenerated.

```bash
flutter create .          # once: generates android/ios/linux/macos/windows/web
flutter pub get
flutter test              # run the engine tests
flutter run -d <device>   # windows|linux|macos|chrome|<android/ios id>
flutter build web --release
```
One-command everything: `scripts/build_all.ps1` (Windows) / `scripts/build_all.sh`
(Linux/macOS). CI that compiles all platforms + publishes the web build:
`.github/workflows/build.yml` (triggers on a `v*` tag).

---

## 2. Directory map

```
lib/src/
  core/        AO data model (constants, ini, emote, character, frame effects,
               validator, history)
  discovery/   folder → character (scanner, builder, organizer)
  imaging/     codecs, colour ops, region edit, compositor, buttons, bulk, webp
  animation/   clip, easing, recipe engine, keyframe timeline, lipsync
  presets/     built-in preset library
  plugins/     JSON pack model + extension registry
  platform/    Workspace + save/webp platform seams (conditional imports)
  ui/          Flutter app: app_state, theme, widgets/, screens/
```

---

## 3. Module & function reference

### core/ao_constants.dart
Constants + enums. Key items:
- `kAnimatedExtensions`, `kStaticExtension`, `kSpriteExtensionPriority`,
  `kImportableImageExtensions` — extension lists / priority.
- `SpritePrefix` — `.idle`='(a)', `.talk`='(b)', `.post`='(c)' (+ `/` folder
  variants), `.all`.
- `enum EmoteModifier { idle(0), preanim(1), zoom(5), zoomPreanim(6) }` —
  `.value`, `.label`, `EmoteModifier.fromValue(int)`.
- `enum DeskModifier { hide(0)…showDuringPreCentered(5) }` — `.value`, `.label`,
  `.fromValue`, `DeskModifier.defaultValue` (= show).
- `enum CourtSide { defense('def')…seance('sea') }` — `.id`, `.label`,
  `CourtSide.fromId`, `.defaultValue` (= witness).
- `enum ScalingMode { smooth, pixel }` — `.id`, `.fromId`.
- `enum FrameEffectKind { sfx, realization, screenshake }` — `.suffix`,
  `.sectionSuffix(spriteRef)`.
- `IniSection` — canonical lower-case section names.
- `AoTiming` — `soundTickMs`=60, `frameDelayUnitSeconds`=0.01, defaults.
- `CharFolder` — `iniName`, `charIcon`, `emotionsDir`, `buttonName(n,{on})`,
  `recommendedButtonSize`=40, `ignoredScanDirs`, `ignoredScanBaseNames`, …
- `kEmoteFieldSeparator`='#', `kNoPreanim`='-'.

### core/ao_ini.dart
Low-level tolerant INI.
- `IniEntry(key, value)`.
- `IniSectionData(name,[entries])` — `.value(k)`, `.intValue`, `.doubleValue`,
  `.boolValue`, `.set(k,v)` (in-place upsert), `.remove(k)`, `.asMap()`,
  `.numericEntries()` (sorted `List<MapEntry<int,String>>`).
- `IniDocument([sections])` — `.section(name)`, `.sectionOrCreate(name)`,
  `.hasSection`, `static parse(text,{repairMangled=true})`, `.serialize()`.
  Repairs run-on numeric lines like `1 = 02 = 0` via `_repairNumericRun`.

### core/emote.dart
- `class Emote` — fields: `comment, preanim, sprite, modifier, deskMod,
  hasDeskField, soundName, soundDelayTicks, soundLoop, blipOverride, video,
  optionsBlock`. `.hasMeaningfulSound`, `Emote.parseLine(value)`, `.toLine()`
  (round-trips field count exactly), `.copy()`.

### core/frame_effect.dart
- `FrameEffectEntry(frame,value)`.
- `FrameEffectSet({spriteRef,kind,entries})` — `.sectionName`,
  `FrameEffectSet.tryFromSection(section)` (null if not a frame section),
  `.toSection()`, `.isEmpty`.

### core/character.dart
The central model.
- `class CharacterOptions` — typed fields (`name, showname, needsShowname, side,
  blips, chat, effects, realization, category, scaling, stretch`) + `extra`
  (preserved unknown keys); `.sideEnum`, `.scalingEnum`.
- `class Character` — `options`, `alternateOptions` (Options2-5), `shouts`,
  `time`, `emotes`, `frameEffects`, `soundLoopByName`, `unknownSections`.
  - `static parse(iniText)` / `static fromIni(doc)` — lossless load.
  - `.serialize()` / `.toIni()` — canonical write (recomputes `number`, modern-
    ises `gender`→`blips`).
  - `.spriteReferences()` — set of emote sprite base names.

### core/validator.dart
- `enum LintSeverity { info, warning, error }`.
- `class LintIssue(severity,message,{emoteIndex,fix})` — `.toString()`.
- `CharacterValidator.validate(c,{scan})` → `List<LintIssue>` (missing sprites,
  count/preanim/sound mistakes, stale frame effects, with fix hints).
- `CharacterValidator.count(issues, minSeverity)`.

### core/history.dart
- `class EditHistory({limit=100})` — `.seed(c)`, `.push(c)`, `.undo()`→Character?,
  `.redo()`→Character?, `.canUndo`, `.canRedo`, `.depth`. Snapshot-based (stores
  serialised ini strings).

### discovery/sprite_scanner.dart
- `enum SpriteState { idle, talk, post, staticImage }`.
- `class SpriteFile{relPath,ext,state,base,isAnimated}`.
- `class SpriteGroup(base)` — `idle/talk/post`, `statics`, `.hasDialogPair`,
  `.hasStatic`, `.isAnimated`, `.representative`, `.suggestedComment`.
- `class ScanResult` — `groups`, `preanimCandidates`, `ignored`, `.isEmpty`.
- `class SpriteScanner` — `.scanDirectory(root)` (dart:io),
  **`.fromPaths(relPaths)`** (pure; the testable core, mirrors AO resolution).

### discovery/character_builder.dart
- `class BuildConfig({name,showname,side,blips,chat,scaling,defaultDeskMod,
  treatBareAsPreanim,guessSounds,preferredFirstNames})`.
- `soundGuesses` map (name substring → sfx).
- `class CharacterBuilder` — `.build(scan,{config})` → `Character` (names,
  preanim detection, sound guesses, preferred-first ordering).

### discovery/organizer.dart
- `typedef ButtonRenderer = Future<Uint8List?> Function(bytes, ext, size)`.
- `typedef ProgressCallback = void Function(done,total,label)`.
- `class OrganizeConfig({targetCharDir,deleteOriginals,generateButtons,
  buttonSize,overwriteExistingButtons})`.
- `FileOp`, `ButtonJob`, `OrganizePlan`.
- `class Organizer({buttonRenderer})` — `.plan(...)`→OrganizePlan,
  `.execute(plan,{source,target,config,onProgress})`,
  `.organize(...)` (plan+execute one-shot). Copies files, writes ini, renders
  buttons.

### imaging/codecs.dart
- `Codecs.decode(bytes,{ext})`, `.decodeFirstFrame(...)`, `.isAnimatedExt`,
  `.frameCount(image)`, `.encodePng(image)` (APNG if multi-frame),
  `.encodeGif(image)`, `.encodeForExtension(image,ext)`,
  `.outputExtensionFor(sourceExt)` (webp/apng→apng fallback, gif→gif, else png).

### imaging/color_ops.dart  ← add recolour features here
- `class ColorOp(type,{nums,strs})` — `.n(k,[f])`, `.s(k,[f])`, `.color(k,[f])`,
  `.copyWith`, `.toJson/fromJson`.
- `class OpPipeline(name,ops,{category,description})` — `.toJson/fromJson`.
- `class ImageOps` — `static apply(image,op)`, `static applyAll(image,ops)`,
  `static register(id,fn)` (plugin hook), `registeredOps`.
- Built-in op ids (33): hueShift, saturation, vibrance, brightness, contrast,
  gamma, exposure, levels, invert, grayscale, sepia, temperature, tint,
  colorize, solidColor, gradientMap, duotone, replaceColor, selectiveHue,
  posterize, threshold, opacity, alphaThreshold, channelSwap, colorBalance,
  splitTone, selectiveSaturation, hsvAdjust, vignette, scanlines, noise,
  chromaShift, pixelate. (Params documented in docs/COLOR_OPS.md.)
- Helpers: `parseHexColor(hex)`→ARGB int?, `formatHexColor(argb)`→'#aarrggbb'.
- Implementation note: ops mutate `img.Image` frames in place; `_eachPixel`
  skips alpha==0 pixels. Ops needing neighbours (chromaShift) clone first.

### imaging/region_edit.dart  ← outfit/region editing
- `class SelectionMask(w,h)` / `.full(w,h)` — `.get/.set`, `.invert`,
  `.combine(other,mode)`, `.selectedCount`.
- `class RegionEditor` — `rectangle`, `ellipse`, `selectByColor(image,x,y,{
  tolerance,contiguous,ignoreTransparent})` (magic wand/flood fill),
  `selectByLuminance`, `feather`, `grow`, `shrink`, `applyOps(image,mask,ops)`,
  `erase(image,mask)`, `fill(image,mask,argb)`.

### imaging/compositor.dart  ← snip + combine sprites
- `class Layer(image,{x,y,scale,angle,opacity,visible,name})`.
- `class CutResult(image,offsetX,offsetY)`.
- `class Compositor` — `cut(src,mask,{trim})`, `cutRect`, `cutEllipse`,
  `place(base,piece,{x,y,scale,angle,opacity})`, `flatten(w,h,layers)`.

### imaging/button_maker.dart
- `class IntRect(x,y,w,h)`.
- `ButtonMaker.renderAuto(bytes,ext,size)` (matches `ButtonRenderer`),
  `.renderComposite({sourceFrame,crop,size,background,foreground,mask,
  selectedOverlay,on})`, `.autoTrimBounds(image)`.

### imaging/bulk_processor.dart
- `enum OutputFormat { keep, png, apng, gif, webp }`.
- `class BulkResult(sourceRel,{ok,outRel,error})`.
- `class BulkProcessor(workspace)` — `.run({files,pipeline,output,webpLossless,
  webpQuality,inPlace,nameSuffix,deleteOriginalOnConvert,onProgress})`. WebP
  output uses `encodeAnimation` for multi-frame images.

### imaging/webp_codec.dart (+ _io / _web)
- `class WebpResult.ok(bytes)` / `.fail(reason)`.
- `abstract WebpEncoder` — `supportsLossy`, `supportsLossless`,
  `encode(image,{lossless,quality})`, **`encodeAnimation(frames,durationsMs,{
  lossless,quality})`**; `WebpEncoder.instance` (active), `WebpEncoder.override(e)`.
- Native (`_io`): `NativeWebpEncoder` — libwebp via FFI (`WebPEncodeRGBA`,
  `WebPEncodeLosslessRGBA`, anim via `libwebpmux` `WebPAnimEncoder*`). ABI
  constants `_kEncoderAbi`/`_kMuxAbi` may need adjusting per libwebp version;
  every call is checked and fails to `WebpResult.fail` (never crashes).
- Web (`_web`): `WebWebpEncoder` — browser canvas (`toDataUrl('image/webp')`),
  still only; animation returns fail (callers fall back to APNG).

### animation/anim_clip.dart
- `class AnimFrame(image,{delayCentis})` — `.delayMs`.
- `class AnimClip(frames)` — `.toImage()`, `.encode({ext})`,
  **`.encodePreferWebp({lossless,quality})`** → `({bytes,ext})` (webp else apng).

### animation/easing.dart
- `class Easing` — `Easing.apply(name,t)`, `Easing.names`, `Easing.register(name,fn)`.
  ~25 curves (linear, easeInOut*, back, bounce, elastic, circ, expo, quint…).

### animation/anim_engine.dart  ← add animation effects here
- `class FrameSpec` — `dx,dy,scale,scaleX,scaleY,angle,opacity,colorOps`;
  `.add(other)` (transforms add, scales multiply, opacities multiply, colorOps
  concat).
- `class AnimRecipe(type,{p,colors,region,ease})` — `.n(k,[f])`, `.toJson/fromJson`.
  `region` (an `IntRect`) makes it animate only that area as a layer.
- `typedef RecipeFn = FrameSpec Function(double t, AnimRecipe r)`.
- `class AnimEngine` — `recipeTypes`, `register(id,fn)` (plugin hook),
  `render(base,recipes,{frames,fps,loop})`→AnimClip (global recipes sum; region
  recipes composite as layers), `renderSpec(base,specAt,{frames,fps})` (used by
  Timeline).
- Built-in recipe ids (40+): none, sway, bob, bounce, float, breathe, shake,
  spin, tilt, wiggle, zoomPulse, jump, glow, flash, pulse, rainbow, tintPulse,
  fadeIn, fadeOut, throb, nod, headShake, swing, drift, orbit, heartbeat,
  strobe, flicker, neon, hologram, glitch, colorCycle, wave, pendulum, vibrate,
  pop, wobble, slideIn, slideOut, squashStretch, twitch, breatheGlow.

### animation/timeline.dart
- `class Keyframe({time,dx,dy,scale,angle,opacity,hue,ease})` — `.toJson/fromJson`.
- `class Timeline(keyframes)` — `.specAt(t)`, `.render(base,{frames,fps})`,
  `.toJson/fromJson`.

### animation/lipsync.dart
- `LipSync.twoState(closed,open,{closedCentis,openCentis})`,
  `.fromVisemes(list,{perFrameCentis,pingPong})`,
  `.auto(base,{mouth,openAmount,frames,fps})` (procedural jaw-drop).

### presets/presets.dart
- `NamedPalette`, `NamedGradient`, `AnimPreset`, `EmoteNameSet`.
- `class PresetLibrary` — `colorPresets`, `palettes`, `gradients`, `animPresets`,
  `emoteNameSets`, `gradientMapOp(g,{strength})`, `totalCount`.

### plugins/pack.dart & extension_registry.dart
- `class PurrfectPack(...)` — `.fromJsonString/fromJson`, `.toJsonString/toJson`,
  `.itemCount`. Fields: colorPresets, palettes, gradients, animPresets,
  emoteNameSets.
- `ExtensionRegistry.instance` — merged getters (`colorPresets`, `palettes`,
  `gradients`, `animPresets`, `emoteNameSets`), `installPack(pack)`,
  `installPackJson(json)`, `removePack(name)`, `registerColorOp/Recipe/Easing`,
  `revision`, `installedItemCount`.

### platform/
- `abstract Workspace` — `root`, `listFiles`, `exists`, `readBytes/readString`,
  `writeBytes/writeString`, `makeDir`, `copy`, `move`, `delete`, static `norm`.
  `MemoryWorkspace` (web/tests; `.put`, `.snapshot`), `IoWorkspace` (native).
  Get one via `createLocalWorkspace(root)` from `workspace_factory.dart`.
- `saveBytes(name,bytes)` (`save_file.dart`) — native dialog / web download.

### ui/
- `AppState extends ChangeNotifier` (`ui/app_state.dart`) — the hub the screens
  use: import, scan/build, edit, undo/redo, previews, live pipeline, apply/bulk,
  animation render/save (WebP default), mixer save, export zip/ini. Read it
  before adding a screen.
- `screens/` — home, editor, color_lab, animation_studio, button_studio, mixer,
  bulk, plugins. `widgets/` — `CheckerImage`, `ZoomCanvas`.

---

## 4. How to add a feature

**A colour op:** implement `static void _myOp(img.Image f, ColorOp op)` in
`color_ops.dart` (use `_eachPixel`; read params via `op.n`/`op.color`), add it to
the `_registry` map, document it in `docs/COLOR_OPS.md`, optionally add a preset.

**An animation recipe:** add `static FrameSpec _myFx(double t, AnimRecipe r)` in
`anim_engine.dart` (set transform fields and/or `colorOps`), register it in
`_registry`, document in `docs/ANIMATION.md`, optionally add an `AnimPreset`.

**An easing curve:** add to `Easing._curves` (or `Easing.register` at runtime).

**A preset / palette / gradient / name set:** add to `PresetLibrary` lists in
`presets/presets.dart`. For user-shippable content, make a JSON pack instead.

**A plugin pack:** author JSON (schema in `docs/PLUGINS.md`); load via the
Plugins screen or `ExtensionRegistry.instance.installPackJson`.

**A screen:** create `ui/screens/foo_screen.dart`, add it to `_dests` and the
`screens` list in `lib/src/app.dart`, and (if it needs a loaded project) to the
`needsProject` index guard. Talk to the engine through `AppState`.

**A new char.ini field:** add the constant/section to `ao_constants.dart`, model
it in `Character`/`Emote`, parse in `fromIni`, write in `toIni`, and add a
round-trip test. Preserve anything you don't model in `unknownSections`/`extra`.

---

## 5. Gotchas

- **`image` package (v4):** mutate frames in place via `getPixel`/`setPixelRgba`;
  iterate `image.frames` (length 1 for stills). Use `copyResize/copyCrop/
  copyRotate/compositeImage`, `encodePng` (APNG when multi-frame), `encodeGif`.
  WebP **decode** works; **encode** does not — that's why `WebpEncoder` exists.
- **WebP is the default output** but the encoder may be unavailable; always go
  through `AnimClip.encodePreferWebp` / `BulkProcessor` which fall back to APNG.
- **FFI ABI:** `webp_codec_io.dart` pokes struct fields by offset and uses ABI
  version constants. If animated WebP fails on a given libwebp build, it falls
  back; adjust `_kEncoderAbi`/`_kMuxAbi` if you need it to succeed.
- **Platform seams:** never import `*_io.dart`/`*_web.dart` directly — import the
  factory (`workspace_factory.dart`, `save_file.dart`, `webp_codec.dart`).
- **Real-time preview** runs the pipeline on a **downscaled** copy
  (`AppState.previewWithPipeline`), then "Apply" bakes at full res. Keep heavy
  work off the main path or move it into isolates.
- **Tests:** `flutter test`. Add a test when you touch the ini model, scanner,
  colour ops, or animation engine.
```
