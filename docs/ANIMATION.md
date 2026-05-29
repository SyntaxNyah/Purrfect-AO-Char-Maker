# Animation

AO sprites are just multi-frame images, so "make the character move/glow" means
"generate an animated `(a)`/`(b)` sprite". Purrfect does that for you — pick a
recipe, tune intensity, export. No animation knowledge required, but full
keyframe control is there if you want it.

Everything exports as a standard animated sprite that works natively in AO.
**Animated WebP is the default** output (native uses `libwebpmux`); if WebP isn't
available on the current platform it transparently falls back to **APNG** (which
is also ideal for 2D visual-novel sprites), so you always get a working file.

## One-click recipes

A recipe is an `AnimRecipe(type, p: {...}, colors: {...}, ease: '...', region: ...)`.
Common params: `intensity`, `cycles`. **Stack** several to combine them.

### Movement
`sway`, `bob`, `bounce`, `float`, `breathe`, `shake`, `spin`, `tilt`, `wiggle`,
`zoomPulse`, `jump`, `nod`, `headShake`, `swing`, `drift`, `orbit`, `heartbeat`

### Visual effects
`glow` (color), `flash`, `pulse`, `rainbow`, `tintPulse` (color), `neon`
(color), `hologram` (color), `glitch`, `colorCycle`, `strobe`, `flicker`,
`fadeIn`, `fadeOut`, `throb`

> `none` is the identity recipe. Recipe ids are discoverable at runtime via
> `AnimEngine.recipeTypes`.

### Stacking example — "float + glow + rainbow"
```dart
AnimEngine.render(base, [
  AnimRecipe('float',   p: {'intensity': 3}),
  AnimRecipe('glow',    p: {'intensity': 0.6}, colors: {'color': '#FFB8E0FF'}),
  AnimRecipe('rainbow', p: {'cycles': 1}),
], frames: 24, fps: 14);
```
Transforms add, scales multiply, opacities multiply, and colour ops concatenate.

## Easing
Every recipe takes an `ease` (see `Easing.names`): `linear`, `easeInOutSine`,
`easeOutQuad`, `easeOutBack`, `easeOutBounce`, `elastic`, and more. Easing is
what makes motion feel snappy or springy instead of robotic.

## Animate just a part (wave a hand, spin a limb)
Give a recipe a `region` (a rectangle of the sprite). The rest stays still while
that region animates as a layer on top:
```dart
AnimRecipe('swing',
  p: {'intensity': 14, 'cycles': 2},
  region: IntRect(x, y, w, h));   // the hand/arm box
```

## Lip-sync
```dart
import 'package:purrfect/src/animation/lipsync.dart';

// Easiest: closed + open mouth sprites → a looping talking animation
LipSync.twoState(closedImage, openImage);

// Several mouth shapes (visemes), cycled naturally
LipSync.fromVisemes([closed, half, open], pingPong: true);

// Zero extra art: rough procedural jaw-drop from a single sprite
LipSync.auto(closedImage, openAmount: 0.35);
```
Save the result as `(b)<sprite>.apng` and it becomes the talking animation.

## Manual keyframe timeline (advanced)
```dart
import 'package:purrfect/src/animation/timeline.dart';

final tl = Timeline([
  Keyframe(time: 0.0, dy: 0,   ease: 'easeOutQuad'),
  Keyframe(time: 0.5, dy: -12, scale: 1.05),
  Keyframe(time: 1.0, dy: 0),
]);
final clip = tl.render(base, frames: 16, fps: 12);
```
Each keyframe sets `dx, dy, scale, angle, opacity, hue` and the easing for the
segment that starts at it. Purrfect interpolates the rest.

## In the app
The **Animate** screen: pick a preset or add effects, tune intensity/frames/fps,
choose easing, watch the live looping preview, then **Save as (b) talk** or
**(a) idle** — the file is added to your project *and* downloaded.

## Adding a recipe (native plugin)
```dart
ExtensionRegistry.instance.registerRecipe('mySpin', (t, r) =>
    FrameSpec()..angle = 360 * r.n('cycles', 1) * t);
```
Packs can then reference `"type": "mySpin"` in their `animPresets`.
