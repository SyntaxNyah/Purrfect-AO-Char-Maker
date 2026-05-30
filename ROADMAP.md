# Roadmap

Legend: ✅ done · 🟡 partial · ⬜ planned

## Core engine
- ✅ Tolerant `char.ini` reader/writer with run-on-line repair
- ✅ Lossless `Character` model (preserves unknown sections/keys)
- ✅ Emotes, SoundN/T/L/B, Videos, OptionsN, Options2–5, Shouts, Time
- ✅ Frame effects (`_FrameSFX` / `_FrameRealization` / `_FrameScreenshake`)
- ✅ Validator / linter with suggested fixes
- ✅ Snapshot undo/redo
- ⬜ Per-emote `[Options*]` editing UI (model already preserves it)

## Automation
- ✅ Sprite scanner (a/b/c, statics, subfolders, preanims, extension priority)
- ✅ Auto character builder (names, preanim detection, sound guesses)
- ✅ Organizer (folders, file copy/move, auto buttons, ini)
- ✅ Auto `char_icon.png` generation (head/face framing, size 40–128, choose the
  source emote, optional border/background overlay)
- ⬜ Auto `credits.txt` scaffolding

## Imaging & colour
- ✅ Decode webp/apng/gif/png (+ jpg/bmp/tga/tiff/…)
- ✅ ~25 composable colour ops + pipeline
- ✅ Hundreds of presets / palettes / gradients
- ✅ Region/outfit editor (magic wand, masks, feather, recolour/erase/fill)
- ✅ 43 colour ops incl. split-tone, vignette, scanlines, grain, chroma shift,
  pixelate, solarize, dither, cross-process, bleach-bypass, sharpen, blur
- ✅ Custom colour wheel/picker → recolour / tint / solid / gradient (blendable)
- ✅ Crop, auto-trim & background removal (frame-aware; uniform across (a)/(b))
- ✅ Sprite compositor / mixer (snip + stack layers; head-on-body) with a
  two-folder workflow (load a 2nd character's folder to graft parts from),
  **multiple snips at once**, **mouse drag/scale/rotate**, and a **Layers mode**
  that links separated part-files (eyes/brows/body/…) into one sprite
- ✅ Bulk recolour, convert, crop/trim & rename (recolour/edit re-encode WebP
  sprites in place — no more phantom `.apng` that left the original untouched)
- ✅ WebP encode: web (canvas) + native (libwebp via FFI), bundled in CI builds
- ✅ Animated WebP export (native via libwebpmux); **WebP is the default output**,
  auto-falling back to APNG where WebP isn't available (web build, or native
  without libwebpmux)
- ⬜ GPU fragment-shader real-time path (CPU preview works now)
- ⬜ Palette-swap (exact indexed remap) op
- ✅ Outline / drop-shadow / glow image ops (spatial ops that draw into the halo)

## Animation
- ✅ ~88 stackable recipes with easing (incl. outline/glow/shadow effect recipes)
- ✅ **Frame-by-frame** assembler (pick/reorder existing sprites → one animation;
  fps, reverse, ping-pong, canvas alignment)
- ✅ Region-targeted animation (wave a hand, spin a limb)
- ✅ Manual keyframe timeline
- ✅ Lip-sync (two-state, multi-viseme, rough auto)
- ⬜ Onion-skinning + scrubbable timeline UI
- ⬜ Per-frame SFX/realization/screenshake authoring UI (model supports it)

## Plugins & sharing
- ✅ JSON content packs (presets/palettes/gradients/animations/name sets)
- ✅ Pack install/remove (works on web)
- ✅ Native code hooks (ops/recipes/easings)
- ⬜ Pack browser / online registry
- ⬜ Export current project's custom presets as a pack

## Platforms
- ✅ Single codebase: Windows / Linux / macOS / Android / iOS / Web
- ✅ In-memory workspace + zip export for uniform behaviour
- ✅ Folder import on every platform (native dir dialog / web `webkitdirectory`)
- 🟡 Direct folder write on desktop (currently zip export; folder write planned)
- ⬜ Android SAF / `MANAGE_EXTERNAL_STORAGE` flow for in-place folder editing
- ⬜ Recent projects / autosave

## UI polish
- ✅ Button & Icon Studio: head/face vs full-body framing (face default), size,
  zoom, crop-position offsets, and **image overlays** (KFO-style borders +
  backgrounds) for both buttons and the char_icon
- ✅ Dedicated **char.ini builder** screen (the full `[Options]` block: name,
  showname, blips, chat, side, category, scaling, …)
- ✅ About / credits (maintainer + repo) in the toolbar and on Home
- ✅ Performance: lazy active-screen build, decoupled/debounced previews
  (incl. the Mixer), cached chip lists, smooth (non-pixelated) scaling
- ✅ Performance: field editing (Emotes/Character) is no longer re-rendered per
  keystroke — it commits on blur, and the preview is cached per sprite revision
- ✅ Performance: allocation-free per-pixel op core (sequential pixel cursor),
  bulk/recolour/edit loops yield so the UI stays responsive
- ✅ Keyboard shortcuts (undo/redo, import/export, screen jumps, F1 help) + a
  top toolbar with undo/redo + quick actions
- ✅ Mixer tools: snip-crop/ellipse, flip H/V, feather, recolour the snip,
  output crop, center/reset
- 🟡 Home, Character (char.ini), Editor, Colour Lab, Animate, Buttons, Edit,
  Mixer, Bulk, Plugins screens
- 🟡 App icon: `flutter_launcher_icons` pipeline wired (`assets/icon/app_icon.png`,
  `dart run flutter_launcher_icons`) — placeholder art, swap in the Pinsel mascot
- ⬜ Drag-and-drop import
- ⬜ Move heavy bakes (bulk/animation export) into isolates
- 🟡 Button overlay/border + background compositor UI (done for auto buttons +
  char_icon; the full mask/crop `ButtonMaker.renderComposite` UI is still planned)
- 🟡 Region picker overlay (drag a box) — done in the Mixer (snip/arrange canvas);
  still planned for region animation/outfit edits
- ⬜ Theming / accessibility pass
