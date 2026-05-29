# Colour operations

Every recolouring feature is a `ColorOp` — a `type` id plus numeric (`nums`) and
string/colour (`strs`) parameters. A list of them is an `OpPipeline`. The same
pipeline powers the live preview, bulk processing, presets, and plugin packs.

Colours are hex strings: `#rrggbb`, `#aarrggbb`, or without the `#`. All ops
**skip fully transparent pixels** so silhouettes stay clean.

## Op reference

| `type` | Params (`nums` unless noted) | Effect |
|--------|------------------------------|--------|
| `hueShift` | `degrees` (−180..180) | rotate hue |
| `saturation` | `amount` (0..3, 1 = none) | multiply saturation |
| `vibrance` | `amount` (−1..1) | boost low-sat pixels more |
| `brightness` | `amount` (0..2) | multiply brightness |
| `contrast` | `amount` (0..2) | contrast around mid-grey |
| `gamma` | `amount` (>0) | gamma correction |
| `exposure` | `stops` (−x..x) | exposure in stops |
| `levels` | `inBlack,inWhite,outBlack,outWhite,gamma` | photoshop-style levels |
| `invert` | — | invert RGB |
| `grayscale` | `amount` (0..1) | desaturate to luma |
| `sepia` | `amount` (0..1) | sepia tone |
| `temperature` | `amount` (−1 cool .. 1 warm) | white-balance shift |
| `tint` | `color`(strs), `amount` (0..1) | blend toward a colour |
| `colorize` | `hue, saturation, strength` | **recolour preserving brightness** (the OC staple) |
| `solidColor` | `color`(strs) | flat fill, keep alpha (silhouette) |
| `gradientMap` | `stopN`(strs)+`posN`, `strength` | map luma through a gradient |
| `duotone` | `shadow,highlight`(strs), `strength` | two-tone by luma |
| `replaceColor` | `from,to`(strs), `tolerance, softness` | swap one colour for another |
| `selectiveHue` | `center, width, shift, saturation` | shift only hues in a band |
| `posterize` | `levels` (≥2) | quantise tones |
| `threshold` | `level` (0..255) | hard black/white by luma |
| `opacity` | `amount` (0..1) | scale alpha |
| `alphaThreshold` | `level` | clip alpha to 0/255 |
| `channelSwap` | `order`(strs, e.g. `gbr`) | reorder RGB channels |
| `colorBalance` | `r,g,b` (−255..255) | add per-channel offset |

## Examples

Turn a sprite pink without flattening the shading:
```json
{ "type": "colorize", "nums": { "hue": 330, "saturation": 0.8, "strength": 0.95 } }
```

Recolour just the red parts (e.g. a red scarf) to blue:
```json
{ "type": "selectiveHue", "nums": { "center": 0, "width": 25, "shift": 220 } }
```

Swap an exact colour with a soft edge:
```json
{ "type": "replaceColor",
  "strs": { "from": "#FFE03A3A", "to": "#FF3A7BE0" },
  "nums": { "tolerance": 40, "softness": 20 } }
```

Fire gradient map:
```json
{ "type": "gradientMap",
  "strs": { "stop0": "#FF000000", "stop1": "#FFFF5A00", "stop2": "#FFFFFFC0" },
  "nums": { "pos0": 0, "pos1": 0.6, "pos2": 1, "strength": 1 } }
```

## Using ops in code
```dart
import 'package:purrfect/src/imaging/color_ops.dart';

ImageOps.apply(image, ColorOp('hueShift', nums: {'degrees': 120}));
ImageOps.applyAll(image, [
  ColorOp('colorize', nums: {'hue': 200, 'saturation': 0.6}),
  ColorOp('brightness', nums: {'amount': 1.1}),
]);
```

## Region / outfit editing
To affect only part of the image (e.g. the clothes), build a `SelectionMask`
and apply ops through it:
```dart
import 'package:purrfect/src/imaging/region_edit.dart';

final mask = RegionEditor.selectByColor(image, x, y, tolerance: 48); // magic wand
final soft = RegionEditor.feather(mask, radius: 2);
RegionEditor.applyOps(image, soft, [ColorOp('colorize', nums: {'hue': 120})]);
// or: RegionEditor.erase(image, soft) / RegionEditor.fill(image, soft, 0xFF112233)
```
Selections can also be rectangles, ellipses, or luminance bands, and combined
(union/intersect/subtract), grown, or shrunk.

## Adding a new op (native plugin)
```dart
ExtensionRegistry.instance.registerColorOp('myThing', (frame, op) {
  // mutate frame in place using op.n(...) / op.color(...)
});
```
Data packs can then reference `"type": "myThing"`.
