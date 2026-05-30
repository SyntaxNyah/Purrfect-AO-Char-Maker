# 🐾 Purrfect AO Char Maker

**The most customizable, most automated Attorney Online / webAO character & button maker — on every platform from one codebase.**

Drop in a folder of sprites → get a finished, AO2- **and** webAO-compatible
character: an auto-generated `char.ini`, the right folder layout, and
auto-generated emote buttons. Then recolour, animate, lip-sync, and customise
everything — or don't, because every powerful feature has a sensible default.

Runs natively on **Windows, Linux, macOS, Android, iOS**, and as a **website**
(Flutter Web) so people can use and share it straight from a browser.

> Built from scratch with [KFO-CharMaker](https://github.com/) and
> [DROButtonMaker](https://github.com/Chrezm/DROButtonMaker) as inspiration —
> aiming to be vastly more capable than both. Format details were verified
> against the official AO docs and the AO2 reference client. AGPL-3.0.

---

## ✨ What it does

### Automate everything (optional)
- **Folder → character.** Scans a folder of images, detects `(a)`/`(b)`/`(c)`
  idle/talk/post sprites, static sprites, sub-folder sprites, preanimations, and
  animation formats — then writes a correct `char.ini` for you.
- **Auto folders + file moving.** Builds the character folder, an `emotions/`
  folder, and lays everything out the way AO expects.
- **Auto buttons.** Generates `buttonN_off.png` icons for every emote
  (trim → centre square → scale). Drop your own in to override.
- **Smart guesses.** Friendly emote names, preanimation detection, and optional
  sound-effect guesses — all adjustable.

### Customize everything
- **Real-time Colour Lab** — hue / saturation / brightness / contrast with live
  preview, plus **hundreds of presets**, palettes, gradient maps, and
  "Make it `<colour>`" recolours that **preserve shading** (perfect for OCs —
  turn a sprite pink without flattening it).
- **Custom colour wheel** — pick *any* colour (wheel / area / sliders / hex) and
  blend it in as a recolour, tint, solid fill, or gradient — stack as many as
  you like on top of the presets.
- **Effects** — add an **outline**, **outer glow** or **drop shadow** around a
  sprite, **sharpen**/**blur**, or film looks (cross-process, bleach-bypass,
  solarize, dither) — all blendable like any other preset.
- **Region / outfit editing** — magic-wand colour selection, rectangle/ellipse
  masks, feathering, grow/shrink; then recolour just the clothes, erase a
  region, or paint a fill.
- **Crop, auto-trim & background removal** — crop sprites (uniform across all
  frames + (a)/(b)), trim transparent margins, or knock out a flat background by
  flood-filling from the corners.
- **Sprite mixer ("frankensprite")** — snip a region from one sprite (e.g. a
  head) and drop it onto another (a body), with position/scale/rotate/opacity,
  then save it as a new emote. Combine **two characters** by loading a **second
  sprite folder** right in the Mixer (kept separate from your project + export).
- **Bulk operations** — recolour, convert, **crop/trim**, or **rename** *every*
  sprite/emote at once (find/replace, prefix/suffix, numbering, case).
- **Format conversion** — import webp/apng/gif/png (and jpg/bmp/tga/tiff/…),
  export PNG/APNG/GIF, and **WebP (lossy + lossless)** — instantly in the web
  build, or via the bundled libwebp on desktop/mobile.

### Animate everything (so anyone can)
- **One-click animation recipes** — sway, bob, bounce, breathe, shake, spin,
  nod, head-shake, swing, drift, orbit, heartbeat, glow, flash, rainbow, pulse,
  neon, hologram, glitch, fade, throb, sparkle, drop-in, spring-in, outline-pulse,
  aura-glow… **stack them** ("move + glow + rainbow") with **easing curves**.
- **Animate just a part** — pick a region to wave a hand or spin a limb.
- **Lip-sync** — give it a mouth-closed + mouth-open sprite (or several visemes)
  and it builds the talking `(b)` animation; a rough one-sprite auto mode exists
  too.
- **~88 stackable effects** and a **custom keyframe timeline** for full control.
- Exports as **animated WebP** by default (bundled libwebp on desktop/mobile;
  browser-native on web), auto-falling back to APNG where WebP isn't available.

### Extend everything
- **Plugin packs** — plain JSON adding presets, palettes, gradients, animations
  and name sets. No install, no recompile, and they work on the **web** too.
- **Native code hooks** — register new colour ops, animation recipes, and easing
  curves.

### Never lose data
- The `char.ini` parser is **lossless**: unknown sections/keys are preserved,
  and it even **repairs** mangled run-on lines found in real-world inis.
- **Undo/redo** and a **validator/linter** that flags missing sprites, count
  mismatches, and preanim mistakes — with plain-language fixes.

---

## 🚀 Quick start

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.22+). The platform project folders are generated on first run.

```bash
# 1. Get the code
cd Purrfect-AO-Char-Maker

# 2. Generate the platform folders (android/ios/linux/macos/windows/web)
flutter create .

# 3. Install dependencies
flutter pub get

# 4. Run it
flutter run -d windows      # or linux / macos / chrome / <android|ios device>
```

**Make the website:**
```bash
flutter build web --release
# Serve build/web/ from any static host (GitHub Pages, Netlify, itch.io, …)
```

See **[docs/BUILD_AND_RUN.md](docs/BUILD_AND_RUN.md)** for per-platform details
(Android/iOS signing, native libwebp, web hosting).

---

## ⬇️ Prebuilt binaries (let GitHub build them)

You don't need to compile anything yourself — GitHub Actions does it for every
platform via [`.github/workflows/build.yml`](.github/workflows/build.yml).

**Open the *Actions* tab → the latest "Build binaries" run.** Each platform's
   output is under **Artifacts** (`purrfect-windows`, `-linux`, `-macos`,
   `-android-apk`, `-web`). Download and unzip.

> Builds run **independently of the tests**, so you still get binaries even if a
> test fails. iOS isn't auto-built (it needs your signing certificate); build it
> locally with `flutter build ios`.

## 📖 Documentation

| Doc | What's inside |
|-----|---------------|
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | **Click-by-click guide to every feature (start here)** |
| [docs/BUILD_AND_RUN.md](docs/BUILD_AND_RUN.md) | Build & run on every platform + the web |
| [docs/WEBSITE.md](docs/WEBSITE.md) | Host it as a website (GitHub Pages, Netlify, …) |
| [docs/CHAR_INI_FORMAT.md](docs/CHAR_INI_FORMAT.md) | Complete AO `char.ini` reference |
| [docs/AUTO_BUILD.md](docs/AUTO_BUILD.md) | How folder → character works |
| [docs/COLOR_OPS.md](docs/COLOR_OPS.md) | Every colour operation + parameters |
| [docs/ANIMATION.md](docs/ANIMATION.md) | Recipes, easing, timeline, lip-sync, regions |
| [docs/MIXER.md](docs/MIXER.md) | Snip & combine sprites (head-on-body) |
| [docs/PLUGINS.md](docs/PLUGINS.md) | Pack JSON schema + native plugins + libwebp |
| [ARCHITECTURE.md](ARCHITECTURE.md) | How the code is organised |
| [ROADMAP.md](ROADMAP.md) | What's done and what's next |
| [docs/FAQ.md](docs/FAQ.md) | Common questions & troubleshooting |

The source is documented heavily — almost every public type and method has a
doc comment explaining what it does and why.

---

## 🧭 Status

This is **v0.1** — a deep, tested engine plus a working cross-platform UI. The
core (INI model, scanner/auto-builder, organiser, image/colour engine,
animation engine, presets, plugins) is complete and unit-tested. Some UI screens
are first-pass and the roadmap lists what's growing next. See
[ROADMAP.md](ROADMAP.md).

## 📜 License

AGPL-3.0. See [LICENSE](LICENSE). Credit to the Attorney Online dev team and the
authors of KFO-CharMaker and DROButtonMaker for format references and
inspiration.
