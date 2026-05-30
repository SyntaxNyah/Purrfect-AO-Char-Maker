# Sprite mixer (frankensprite)

Combine parts of different sprites — the classic "put character A's head on
character B's body". Open the **Mixer** tab.

## The two-folder workflow (most common)

A frankensprite usually mixes **two different characters**, which means **two
separate sprite folders**:

- the **body** comes from your **loaded project** (import it from Home as usual);
- the **part** you graft on (a head, a limb, a hat) comes from a **second
  folder** you load right inside the Mixer.

That second folder is loaded as a **"parts" source**: it's scanned so you can
pick any of its sprites, but it is kept **completely separate** from your
project — it never becomes an emote and is **never exported**. You can load
several, switch between them, and remove them with the ✕.

> Mixing within a *single* project still works too: leave **Snip parts from** on
> *This project*.

## In the app
1. **1 · Body** — pick the sprite (from your project) that forms the bottom.
2. **2 · Part to graft on:**
   - **Snip parts from** — choose *This project*, or a folder you loaded.
   - **Load a 2nd sprite folder…** — dump another character's folder here; it
     becomes a parts source and is auto-selected.
   - **Snip from** — pick which sprite in that source to take a piece of.
3. Toggle **Ellipse snip** (great for heads) or use a rectangle.
4. Drag the **Snip region** sliders (X/Y/Width/Height, as fractions of the
   part) to frame the piece you want.
5. Drag the **Placement** sliders (Pos X/Y on the body, Scale, Rotate, Opacity)
   to position it.
6. Name it and **Save as new emote** — it's added to your project as a static
   sprite and a new emote, ready to export.

## In code (`Compositor`)
```dart
import 'package:purrfect/src/imaging/compositor.dart';

// 1. Snip an ellipse (a head) out of sprite A
final cut = Compositor.cutEllipse(headSprite, IntRect(40, 10, 120, 130));

// 2. Place it on the body
final result = Compositor.place(
  bodySprite,
  cut.image,
  x: 70, y: 20,        // top-left of the placed piece
  scale: 1.0,
  angle: 0,
  opacity: 1.0,
);

// Or stack many layers at once:
final flat = Compositor.flatten(width, height, <Layer>[
  Layer(body),
  Layer(cut.image, x: 70, y: 20, scale: 1.1),
]);
```

`cut` / `cutRect` / `cutEllipse` take any [`SelectionMask`](COLOR_OPS.md#region--outfit-editing),
so you can also snip freeform selections built with the region editor.

## Tips
- Recolour the snipped part first (Colour Lab / region editor) so it matches the
  body's palette.
- Animate the result afterwards in the **Animate** tab — a mixed sprite is just a
  normal sprite.
- Mixing works best when both sprites share a similar scale; use the Scale slider
  to match them.
