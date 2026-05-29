# Sprite mixer (frankensprite)

Combine parts of different sprites — the classic "put character A's head on
character B's body". Open the **Mixer** tab.

## In the app
1. **Body (base):** pick the sprite that forms the bottom layer.
2. **Snip from (overlay):** pick the sprite you want to take a piece from.
3. Toggle **Ellipse snip** (great for heads) or use a rectangle.
4. Drag the **Snip region** sliders (X/Y/Width/Height, as fractions of the
   overlay) to frame the part you want.
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
