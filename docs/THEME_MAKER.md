# AO2 Theme Maker

Design a complete **Attorney Online 2 / webAO** client theme — every widget
position, every colour, every font, every image (PNG/GIF/WebP), sounds and Qt
stylesheets — then export a `.zip` ready to drop into AO2's `base/themes/`.

> Open it from the **Theme** tab (the paintbrush). It needs no character loaded.

This is grounded in the **real client format** the AO2 client reads (Qt
`QSettings` flat INIs): design elements are `name = x, y, w, h`, colours are
`name = r, g, b`, fonts are a `name = size` base plus `name_font` / `name_color`
/ `name_bold` / `name_sharp`. Nothing is invented — and **nothing is lost**:
anything the maker doesn't model (bubble timing inis, effects, sfx, custom fonts)
is preserved verbatim on export.

---

## 1. Start a theme

- **Import theme folder** — pick any existing AO2 theme folder. Pinsel parses
  `courtroom_design.ini`, `courtroom_fonts.ini`, `courtroom_sounds.ini`,
  `courtroom_stylesheets.css`, the lobby equivalents, and loads every image. Edit
  any part, then re-export. Round-trips are lossless.
- **New theme** — start from the built-in 1280×720 starter layout.
- **Random** — roll a cohesive random palette (and optionally fonts / a small
  position jitter). Reproducible per seed.

The header shows the theme **name** (becomes the folder name) and a **size**
button (e.g. `1280×720`). Click it to **resize the theme** — pick a preset
(1920×1080, 720p, the AOHD sizes…) or type a custom width/height, and optionally
**scale every widget (and font) proportionally** so the whole layout adapts to
the new resolution in one click.

---

## 2. The tabs

### Layout
Every positioned widget as an editable **X / Y / W / H** row. Toggle
**Courtroom / Lobby**, filter by name, and **Add** any of the **~95 known
widgets** (a searchable picker grouped by area — Core, IC, OOC, Music/Area,
Pairing, Mute, Emotes, Dropdowns, Interjections, Judge, Penalty, Evidence, Char
select, Timers, Sound, Misc, Checkboxes) — or type a custom name. Editing here
and dragging in **Arrange** stay in sync.

### Colours
Every `r, g, b` colour with a swatch — tap to open the hue-wheel + hex picker.
**Add** from the known colour keys (`ooc_default_color`, `found_song_color`,
`area_free_color`, `area_locked_color`, …) or a custom one.

### Fonts
Per widget: **size**, **font family**, **colour** (swatch → picker), **bold** and
**sharp** (no anti-alias) flags. Any extra siblings a theme carries
(`_sender_color`, `ic_chatlog_showname_color`, …) are preserved. **Add** from the
known font widgets or a custom name.

### Images
**Replace any asset with your own PNG / GIF / WebP.** Slots are grouped (Shouts,
Buttons, Chat, Penalty bars 0–10 for each side, Backgrounds, Char select,
Evidence, Selectors) and show a live thumbnail. Picking a `.gif` for a
`.webp`-named slot writes it under the right name and drops the stale variant —
the client resolves **webp → apng → gif → png** by base name, so it just works.
**Add custom** lets you drop in any file name (e.g. `background.png`).

### Style
- **Courtroom / Lobby stylesheets** — the Qt CSS the client applies, editable as
  text.
- **Sounds** — `courtroom_sounds.ini` key → path rows (objection, realization,
  guilty, …).
- **Design options** — every non-position design key: `showname_align`,
  `showname_extra_width`, `emote_button_spacing`, `char_button_spacing`,
  `evidence_button_size`, `effects_icon_size`, `music_list_animated`,
  `chatbox_always_show`, … Add from the known list or a custom key.

### Arrange (drag everything around)
A live, scaled mock of the courtroom (or lobby). **Drag any widget to move it;
drag its bottom-right corner to resize.** Mouse deltas map 1:1 to theme pixels at
any zoom. Tap empty space to deselect. Toggle **Show art** to drag the *real
images* (chatbox, buttons, bars…) instead of coloured boxes. Moves/resizes update
the Layout tab too.

### Preview (real-client look)
A read-only **approximate render of how it looks in the client** — your images at
their positions with sample text in your fonts and colours — so you can **see the
result before exporting or using it**. The scene/character background comes from a
background pack, so it shows as a placeholder here.

---

## 3. Export

**Export .zip** builds a `<theme name>/…` folder zip containing the regenerated
`courtroom_design.ini`, `courtroom_fonts.ini`, `courtroom_sounds.ini`, the CSS,
the lobby files, every image you set, and every preserved passthrough file.

Drop the folder into your AO2 client's `base/themes/`, then pick it in the
client's **Settings → Theme** (and **Reload theme**).

---

## 4. How it maps to the client (reference)

| File | What it holds | Format |
|------|---------------|--------|
| `courtroom_design.ini` | widget positions, colours, scalars | `name = x, y, w, h` · `name = r, g, b` · `key = value` |
| `courtroom_fonts.ini` | per-widget fonts | `name = size`, `name_font`, `name_color = r,g,b`, `name_bold`, `name_sharp` |
| `courtroom_sounds.ini` | sound effects | `name = path` |
| `courtroom_stylesheets.css` | Qt stylesheet | CSS |
| `lobby_design.ini` / `lobby_fonts.ini` / `lobby_stylesheets.css` | lobby equivalents | as above |
| `*_bubble.webp.ini`, `testimony.ini`, … | animation scaling | `scaling = smooth/pixel` (preserved verbatim) |
| images | `background`, `chatbox`, bars, bubbles, buttons | PNG / WebP / APNG / GIF |

The client resolves an asset by **theme → subtheme → default theme**, and tries
**webp → apng → gif → png** for animated assets (png only for static). Positions
and sizes are multiplied by the user's theme scaling factor at runtime, so design
in 1× pixels.

---

## 5. For developers

Engine (pure Dart, no Flutter): `lib/src/theme/`
- `ao2_theme.dart` — `Ao2Theme` model + `ThemeElement` / `ThemeColor` /
  `ThemeFont` / `ThemeSound` / `ThemeImage` / `ThemeDesign`. `Ao2Theme.fromFiles`
  parses a folder; `buildFiles()` regenerates it; `starter()` is the default;
  `resize(w, h, {scaleElements, scaleFonts})` rescales the whole layout.
- `ao2_theme_defaults.dart` — the catalogues (`kCourtroomWidgets`,
  `kThemeColorKeys`, `kFontWidgets`, `kThemeScalars`, `kThemeImageSlots`).
- `theme_randomizer.dart` — `ThemeRandomizer.randomize` (cohesive HSV palette).

UI: `lib/src/ui/screens/theme_maker_screen.dart` (seven tabs: Layout, Colours,
Fonts, Images, Style, **Arrange** — the draggable `_LayoutCanvas` with a "Show
art" toggle — and **Preview** — the read-only `_ClientPreview`). State + export
live on `AppState` (`theme`, `importThemeFiles`, `randomizeTheme`,
`setThemeImage`, `exportTheme`) so the screen survives navigation. Editing
commits on blur (no per-keystroke recompute).

Add a new known widget/colour/font/scalar by appending to the lists in
`ao2_theme_defaults.dart` — the pickers update automatically.
