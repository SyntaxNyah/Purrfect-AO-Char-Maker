# Sprite mixer (frankensprite)

Combine parts of different sprites — the classic "put character A's head on
character B's body", **or** stack a character that ships as separate layers
(eyes, eyebrows, body, an arm…) back into one sprite. Open the **Mixer** tab.

The Mixer has **three modes** (the toggle at the top of the canvas):

| Mode | What it's for | Mouse |
|------|---------------|-------|
| **Arrange** | Place snipped parts on a body | Drag a part to move · drag its corner to scale (or scroll the wheel) · drag the round handle to rotate |
| **Snip** | Choose *what* to cut from a source sprite | Drag the box to move · drag a corner to resize |
| **Layers** | "Link everything" — stack whole, pre-aligned files | (no dragging needed — they line up by themselves) |

Every mouse action also has a **slider** in the right-hand panel, so you can be
pixel-precise or skip the mouse entirely.

---

## Arrange + Snip — snip parts onto a body

A frankensprite usually mixes **two different characters**, i.e. **two separate
sprite folders**:

- the **body** comes from your **loaded project**;
- each **part** you graft on comes from your project *or* a **second folder** you
  load right inside the Mixer (it's kept completely separate and is **never
  exported** — just a palette of parts).

### Steps
1. **Body** — pick the sprite (from your project) that forms the bottom.
2. **Snips** — press **+** to add a snip. You can add **as many as you like**
   (a head *and* a hat *and* an accessory). Each row in the list is one snip;
   tap it to edit, use the **copy** icon to duplicate, the **trash** to remove.
3. For the selected snip:
   - **Snip parts from** — *This project* or a folder you loaded
     (**Load a 2nd sprite folder…**).
   - **Snip from** — which sprite to take a piece of.
   - **Snip region** — toggle **Ellipse** (great for heads), then frame it with
     **X / Y / Width / Height** *or* switch the canvas to **Snip** mode and drag
     the box. **Flip H/V** and **Feather** (soften the cut edge) are here too.
   - **Recolour the snip** — **Hue / Saturation / Brightness** retint just this
     piece so it matches the body.
   - **Placement** — **Pos X/Y, Scale, Rotate, Opacity**, or just drag/scale/
     rotate it on the canvas in **Arrange** mode. **Center** snaps it.
4. **Crop output** — trim **Left / Top / Right / Bottom** off the finished image.
5. Name it and **Save as new emote** — it's added to your project as a static
   sprite and a new emote, ready to export.

> **Reset snip** (top-right) restores the selected snip's defaults.

---

## Layers — for art where everything is separated

Some art ships **each feature as its own file**, already drawn on the same
canvas: `eyes.png`, `eyebrows.png`, `body.png`, `arm.png`, all transparent
except their one part. You don't want to snip or position those — you just want
them **stacked**.

Switch the canvas to **Layers** mode:

1. **Load a sprite folder…** (or use *This project*).
2. **Add all** from that source in one click — every sprite becomes a layer.
   (Or **Add one layer** at a time.)
3. The list is the stack, **top of the list = on top**. For each layer:
   - drag-free **▲ / ▼** to reorder, the **checkbox** to show/hide it, an
     **opacity** slider, and **✕** to remove.
   - change its **sprite** (and **From** source) with the dropdowns.
4. **Crop output** if you want, name it, and **Combine & save as new emote**.

Layers are composited at their **native position** (top-left), so pre-aligned
parts line up exactly with no fiddling.

---

## Performance

Each snipped piece is **baked once** (only when its crop/recolour/source change)
into a small cached image; moving, scaling and rotating it on the canvas is a
live transform of that cache — no re-compositing per frame. Only **Save** renders
the full-resolution result.

---

## In code (`Compositor`)
```dart
import 'package:pinsel/src/imaging/compositor.dart';

// 1. Snip an ellipse (a head) out of sprite A
final cut = Compositor.cutEllipse(headSprite, IntRect(40, 10, 120, 130));

// 2. Place it centred on the body (rotates in place)
final result = Compositor.placeCentered(
  bodySprite,
  cut.image,
  cx: 100, cy: 60,    // centre, in body pixels
  scale: 1.0, angle: 0, opacity: 1.0,
);

// Or stack whole, pre-aligned layers at native position:
final flat = Compositor.flatten(width, height, <Layer>[
  Layer(bodyImage),
  Layer(eyesImage),
  Layer(eyebrowsImage),
]);
```

`cut` / `cutRect` / `cutEllipse` take any
[`SelectionMask`](COLOR_OPS.md#region--outfit-editing), so you can also snip
freeform selections built with the region editor.

## Tips
- Recolour a snipped part (the Hue/Sat/Bri sliders, or the Colour Lab) so it
  matches the body's palette.
- Animate the result afterwards in the **Animate** tab — a mixed sprite is just a
  normal sprite.
- Mixing works best when both sprites share a similar scale; use Scale to match.
