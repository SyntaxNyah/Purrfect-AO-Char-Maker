# FAQ & troubleshooting

**Is the output really AO-compatible?**
Yes — Pinsel writes the same `char.ini` format and sprite/button layout the
AO2 reference client and webAO read. The parser/writer are unit-tested against
real-world inis, and the format was verified against the official docs and AO2
source. See [CHAR_INI_FORMAT.md](CHAR_INI_FORMAT.md).

**Will it wreck my existing char.ini?**
No. The model is lossless — unknown sections and keys are preserved, and the
reader even repairs corrupted run-on lines. Re-opening and re-saving a character
keeps everything it doesn't understand.

**What image formats can I import?**
webp, apng, gif, png, plus jpg/jpeg, bmp, tga, tiff, ico, pnm, psd, exr, and
more. Output is PNG/APNG/GIF everywhere, and WebP (lossy + lossless) on the web
build or with libwebp on native.

**Why is WebP export unavailable on my desktop build?**
Pure-Dart can't encode WebP yet, so native builds use `libwebp` via FFI. Install
or bundle it (see [PLUGINS.md](PLUGINS.md#native-libwebp)). The **web** build
encodes WebP with the browser's own codec, no setup needed.

**Animated WebP**
WebP (including **animated** WebP) is the default export. Native builds produce
animated WebP via `libwebpmux`; if it (or libwebp) isn't present, or you're on
the web build, the tool **automatically falls back to APNG** so you always get a
working animated sprite. To guarantee WebP on desktop, install libwebp +
libwebpmux (see [PLUGINS.md](PLUGINS.md#native-libwebp)).

**How do I recolour just the clothes / hair?**
Use the region editor: magic-wand select the colour, feather it, then apply a
`colorize`/`hueShift` pipeline through the mask. See
[COLOR_OPS.md](COLOR_OPS.md#region--outfit-editing).

**How do I crop a sprite or remove its background?**
Open the **Edit** tab: toggle **Auto-trim**, **Remove background** (corner flood
fill, with a tolerance slider), and/or drag the **crop** sliders, then **Apply**
(this emote) or **All sprites**. Crop/trim stay aligned across all frames and an
emote's (a)/(b)/(c).

**How do I pick a custom colour (not just presets)?**
In the **Colour Lab**, tap **Pick colour…** for the colour wheel, then blend it
in as Recolour / Tint / Solid / Gradient. They stack with the presets and
sliders.

**Can I import a whole folder?**
Yes — **Home → Import folder**. On desktop/mobile it's a directory picker; on the
website it's a folder upload. Sub-folder structure is preserved, and an existing
`char.ini` in the folder is loaded as-is.

**How do I put one character's head on another's body?**
Open the **Mixer**. Your **body** is a sprite from the loaded project; for the
head, click **Load a 2nd sprite folder…** and dump the other character's folder
in — it's added as a "parts" source you can snip from, but stays out of your
project and export. Then frame the snip, place it, and **Save as new emote**.
See [MIXER.md](MIXER.md).

**I recoloured/edited "All sprites" but nothing changed — why?**
That was a bug with **WebP** sprites (the default format): the edit was written to
a stray `.apng` while the original `.webp` was left in place. It's fixed — recolour
and crop/trim now re-encode each sprite **in place** in its own format. Re-run the
action.

**Is there keyboard control / undo buttons?**
Yes. Every screen has a top **toolbar** with **undo/redo** (and import/export)
buttons, and there are global shortcuts: `Ctrl/⌘+Z` undo, `Ctrl/⌘+Y` (or
`Ctrl/⌘+Shift+Z`) redo, `Ctrl/⌘+S`/`E` export, `Ctrl/⌘+O` import, `Ctrl/⌘+1…9`
to switch screens, `F1` for the full list. See [SHORTCUTS.md](SHORTCUTS.md).

**Recolour / bulk / animation feel slow or freeze — anything I can do?**
It's a lot faster now: the per-pixel engine is allocation-free, live previews
run on a downscaled copy, and bulk/recolour/edit jobs yield so the **progress
bar updates** instead of the window freezing. The big one-off **bakes** (recolour
ALL, convert ALL, animation export at full res) still take a moment on large
sprite sets — watch the status bar. Tips: recolour the **selected emote** (just
`Apply`) while dialling in a look, then do **All sprites** once; keep sprite
dimensions reasonable; the native WebP encoder (desktop release / web) is much
faster than the APNG fallback.

**Can it just play my frames in order (real frame-by-frame), not only effects?**
Yes. **Animate → Frames**: tap sprites to add them as ordered frames, set
**fps**, and optionally **Reverse** / **Ping-pong**; differently-sized frames are
auto-aligned onto a shared canvas. **Save as (b)/(a)** exports them as one
animated WebP (APNG fallback). Need ≥2 frames. (The **Effects** mode is the
procedural one.) See [ANIMATION.md](ANIMATION.md#frame-by-frame-assemble-given-frames).

**How do I change the app icon?**
Drop a 1024×1024 PNG at `assets/icon/app_icon.png` and run
`dart run flutter_launcher_icons` — see `assets/icon/README.md`.

**How do I make a sprite move if I can't animate?**
Open the **Animate** screen, click a preset (e.g. "Happy Bounce" or "Magical"),
maybe drag the intensity, and **Save**. That's it — see
[ANIMATION.md](ANIMATION.md).

**Can I use it without installing anything?**
Use the web build in a browser — import images, edit, and download a `.zip`. Host
`build/web/` anywhere static (see [BUILD_AND_RUN.md](BUILD_AND_RUN.md#the-website)).

**`flutter create .` — is that safe?**
Yes. It only generates the missing platform folders and standard config; your
`lib/`, `test/`, `assets/`, and docs are untouched. The platform folders are
gitignored on purpose so the repo stays lean.

**The "Emotes/Colour/Animate" tabs say "no project".**
Import sprites first (Home → Import sprite files / Import folder). Those screens
need a loaded character.

**Where are my edits stored?**
In an in-memory project (uniform across platforms). Use **Export .zip** (full
character with buttons) or **Export char.ini** to write them out. Autosave /
recent-projects are on the roadmap.

**How do I add my own presets/animations for others to use?**
Author a JSON pack (see [PLUGINS.md](PLUGINS.md)) — it works on desktop, mobile
**and** the web with no code.

**It runs slowly on a huge sprite while dragging sliders.**
The live preview is computed on a downscaled copy for speed; "Apply" then bakes
at full resolution. Very large bulk jobs run sequentially today — isolate-based
parallelism is on the roadmap.
