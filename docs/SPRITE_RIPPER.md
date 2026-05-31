# Sprite Sheet Ripper

Slice a **sprite sheet** (a grid/collage of visual-novel character expressions)
into individual, transparent AO sprites — then add them straight to your
character or download them as a `.zip`.

> Open it from the **Ripper** tab (the grid icon). It needs no character loaded.

---

## 1. Load a sheet

Click **Load sheet** and pick any image (PNG, WebP, JPG, GIF…). The sheet shows
with detection boxes overlaid. The loaded sheet is remembered, so leaving and
returning to the tab keeps it.

## 2. Pick a mode

### Auto detect (any layout)
Finds each sprite automatically, even when the sheet is an irregular collage
(different sizes, circular cut-outs, ragged gutters). It works by **flood-filling
the background inward from the borders** — so a white shirt on a white sheet
stays part of the sprite (interior background isn't reachable from the edge) —
then grouping the remaining "islands" into sprites.

Tune it:
- **Background tolerance** — how close to the sampled corner colour counts as
  background.
- **Minimum sprite size** — ignores specks/noise below this.
- **Merge gap** — joins pieces of one sprite that are slightly apart (a stray
  hand, hair tuft, floating accessory).
- **Padding** — breathing room around each detected sprite.
- **Trim to content** — tightens each box to the actual pixels.

### Grid (uniform sheets)
For evenly-spaced sheets: set **Columns / Rows**, **Offset X/Y**, **Gutter X/Y**
and optional fixed **Cell W/H** (0 = derive to fill the sheet).

## 3. Refine

Each detected sprite is a numbered box on the sheet. **Tap a box to
include/exclude it.** Use **All / None** to bulk-toggle. The count shows how many
are selected.

## 4. Background removal

Leave **Remove background** on to make the sheet's background transparent in each
exported sprite (with its own **tolerance**). Turn it off to keep the sprite as a
rectangle (e.g. for sheets that already have transparency or a wanted backdrop).

## 5. Export

- **Add to character** — extracts each selected sprite and adds it to your
  current character as a new emote (or builds a new character if none is loaded).
  From there, recolour / animate / make buttons as usual.
- **Download as .zip** — saves the sprites as PNG files in a zip.

Set a **Name prefix** to control the file names (`sprite1`, `sprite2`, …).

---

## For developers

Engine (pure Dart, no Flutter): `lib/src/imaging/sprite_sheet.dart`
- `SpriteSheet.grid(w, h, GridSpec)` — uniform cells.
- `SpriteSheet.autoDetect(image, AutoSpec)` — border-background flood +
  8-connected component labelling + near-box merge + trim, row-major.
- `SpriteSheet.extract(image, rect, {removeBg, bgColor, tolerance})` — crop one
  cell and knock the surrounding background transparent.

UI: `lib/src/ui/screens/sprite_ripper_screen.dart`. Export goes through
`AppState.exportSheetCells(...)` (encode PNGs → `addSprites` or zip + download);
the loaded sheet persists on `AppState.ripperSheetBytes`.
