# FAQ & troubleshooting

**Is the output really AO-compatible?**
Yes — Purrfect writes the same `char.ini` format and sprite/button layout the
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
