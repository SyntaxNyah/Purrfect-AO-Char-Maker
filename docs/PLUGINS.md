# Plugins & extensions

Two ways to extend Pinsel:

1. **Content packs** — plain JSON. No code, no recompile, and they work on the
   **web build** too. This is how most people extend the app.
2. **Native code plugins** — register new colour ops, animation recipes, and
   easing curves in Dart (desktop/mobile builds).

## Content packs (JSON)

A pack adds presets, palettes, gradients, animation presets, and emote-name
sets. Install one from the **Plugins** screen ("Import pack") — on web this is a
file upload; everything is parsed and merged at runtime.

### Schema
```json
{
  "name": "My Pack",
  "author": "you",
  "version": "1.0.0",
  "description": "what it adds",

  "colorPresets": [
    { "name": "Cyberpunk", "category": "Pack",
      "ops": [
        { "type": "duotone", "strs": { "shadow": "#FF0B132B", "highlight": "#FFFF2D95" } },
        { "type": "saturation", "nums": { "amount": 1.2 } }
      ] }
  ],

  "palettes": [
    { "name": "Pastels", "category": "Pack",
      "colors": ["#FFFFADAD", "#FFA0C4FF", "#FFBDB2FF"] }
  ],

  "gradients": [
    { "name": "Cotton Candy", "stops": ["#FFFF8FB1", "#FFB28DFF", "#FF8FE3FF"] }
  ],

  "animPresets": [
    { "name": "Hype", "category": "Pack", "frames": 14, "fps": 18,
      "recipes": [
        { "type": "bounce", "p": { "intensity": 14 }, "ease": "easeOutQuad" },
        { "type": "glow", "p": { "intensity": 0.6 }, "colors": { "color": "#FFFFE08A" } }
      ] }
  ],

  "emoteNameSets": [
    { "name": "VTuber", "names": ["Idle", "Talk", "Happy", "Angry"] }
  ]
}
```

- **Colour ops** use any `type` from [COLOR_OPS.md](COLOR_OPS.md) (or a
  registered native op). See that doc for each op's parameters.
- **Recipes** use any `type` from [ANIMATION.md](ANIMATION.md). They may include
  `region` (`[x,y,w,h]`) and `ease`.
- Colours are hex strings (`#aarrggbb` / `#rrggbb`).

A working example ships at `assets/presets/example_pack.json` — copy it, edit,
and import it.

### Loading packs in code
```dart
ExtensionRegistry.instance.installPackJson(jsonString);
// merged lists:
ExtensionRegistry.instance.colorPresets;   // built-ins + all packs
ExtensionRegistry.instance.animPresets;
```

## Native code plugins
```dart
final reg = ExtensionRegistry.instance;

reg.registerColorOp('myThing', (frame, op) {
  // mutate `frame` (an img.Image) using op.n('x'), op.color('c'), ...
});

reg.registerRecipe('mySpin', (t, r) =>
    FrameSpec()..angle = 360 * r.n('cycles', 1) * t);

reg.registerEasing('myEase', (t) => t * t * (3 - 2 * t));
```
Once registered, packs can reference these ids as data.

## Native libwebp
WebP is the **default** export format. Encoding on desktop/mobile uses `libwebp`
via `dart:ffi`:
- **Still** WebP — `WebPEncodeRGBA` / `WebPEncodeLosslessRGBA` (in `libwebp`).
- **Animated** WebP — `WebPAnimEncoder*` (in `libwebpmux`), so install
  **both** `libwebp` and `libwebpmux` for animated WebP on desktop.

Decoding always works without these. If a library is missing, the app
**automatically falls back to APNG/GIF** (and still WebP falls back to PNG), so
nothing breaks. The web build needs none of this — it uses the browser's codec
for still WebP and falls back to APNG for animation.

When the app falls back, the save status line names the reason (e.g. "libwebpmux
not found"), so you can tell a missing library apart from a real encode error.

Install / bundle libwebp:
- **Windows** — put `libwebp.dll` **and `libwebpmux.dll`** (+ `libsharpyuv.dll`)
  next to the executable. `scripts/build_all.ps1` does this automatically for
  local Release builds (best-effort, via vcpkg); CI release artifacts already
  bundle them.
- **Linux** — `apt install libwebp7 libwebpmux3` / `dnf install libwebp`, or
  bundle the `.so` files.
- **macOS** — `brew install webp` (or bundle the `.dylib`).
- **Android** — bundle `libwebp.so` per ABI under `android/app/src/main/jniLibs/`.
- **iOS** — statically link libwebp into the Runner.

To swap in a custom encoder entirely:
```dart
WebpEncoder.override(MyEncoder());
```
