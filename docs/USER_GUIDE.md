# 🐾 Purrfect — User Guide

A friendly, click-by-click guide to **every feature**. No coding needed.

If you just want to try it with nothing installed, use the **website build** (see
[WEBSITE.md](WEBSITE.md)) — import images, make your character, download a `.zip`.

---

## Contents
1. [The 60-second version](#1-the-60-second-version)
2. [A few words you'll see](#2-a-few-words-youll-see)
3. [The app layout](#3-the-app-layout)
4. [Home — import & export](#4-home--import--export)
5. [Emotes — edit your character](#5-emotes--edit-your-character)
6. [Colour Lab — recolour sprites](#6-colour-lab--recolour-sprites)
7. [Animate — make sprites move](#7-animate--make-sprites-move)
8. [Buttons — emote icons](#8-buttons--emote-icons)
9. [Edit — crop, trim & remove background](#9-edit--crop-trim--remove-background)
10. [Mixer — snip & combine sprites](#10-mixer--snip--combine-sprites)
11. [Bulk — do everything at once](#11-bulk--do-everything-at-once)
12. [Plugins — add more content](#12-plugins--add-more-content)
13. [Common workflows](#13-common-workflows)
14. [Using your character in AO](#14-using-your-character-in-ao)
15. [Tips & troubleshooting](#15-tips--troubleshooting)

---

## 1. The 60-second version
1. **Home → Import sprite files** (or **Import folder** on desktop) and pick your
   images.
2. Purrfect instantly builds a character: it names your emotes, writes the
   `char.ini`, and gets everything ready.
3. (Optional) Tweak emotes, recolour, or animate using the tabs on the left.
4. **Home → Export .zip**.
5. Unzip into your AO `base/characters/` folder. Done. 🎉

---

## 2. A few words you'll see
- **Emote** — one expression/pose with a button (e.g. "Normal", "Angry").
- **Sprite** — the image file(s) for an emote.
  - `(a)name` = the **idle** animation (when not talking)
  - `(b)name` = the **talking** animation
  - `name` (no prefix) = a **static** (non-animated) sprite
- **Preanimation** — a one-time animation that plays *before* talking (e.g. a
  desk slam). `-` means "none".
- **char.ini** — the text file that tells AO about your character. Purrfect
  writes it for you.
- **Button** — the little icon for each emote in AO's emote picker.

You don't have to memorise these — Purrfect figures them out from your file
names.

---

## 3. The app layout
On the left is a **navigation rail** with these tabs:

| Tab | What it's for |
|-----|---------------|
| 🏠 **Home** | Import sprites/folders, set basics, export |
| ▦ **Emotes** | Edit each emote's settings |
| 🎨 **Colour Lab** | Recolour sprites in real time (+ custom colour wheel) |
| 🎬 **Animate** | Make sprites move / glow / etc. |
| ▢ **Buttons** | Preview & generate emote icons |
| ✂️ **Edit** | Crop, auto-trim, remove background |
| ✦ **Mixer** | Snip parts of sprites together |
| ⧉ **Bulk** | Recolour / convert / **rename** *all* sprites at once |
| 🧩 **Plugins** | Add preset/animation packs |

At the very bottom is a **status bar** showing the latest action and your emote
count. A spinner there means it's working.

> Tabs other than **Home** and **Plugins** say *"No project yet"* until you
> import sprites.

---

## 4. Home — import & export

**Import your art**
- **Import sprite files** — pick one or many images (webp, png, gif, apng, jpg,
  bmp, …). Works everywhere, including the website.
- **Import folder** — pick a whole folder (recursively); sub-folder structure is
  kept. Works on **every** platform, including the website (it uses a folder
  upload there). If the folder already has a `char.ini`, Purrfect loads it as-is
  (nothing is lost); otherwise it auto-builds one.

The moment you import, the status bar tells you what happened (e.g. *"Auto-built
24 emotes from sprites."*).

**Auto-build options** (set these *before* importing for best results, or change
them and press **Regenerate from sprites**):
- **Character name (folder)** — becomes the folder name and the `name` in the
  ini.
- **Side** — where the character stands (Defense, Prosecution, Witness, …).
- **Bare file = preanim** — if an emote has both an `(a)/(b)` pair *and* a plain
  same-named file, treat the plain one as a preanimation. Leave on unless your
  results look odd.
- **Guess sound effects** — auto-fills obvious SFX (e.g. a "slam" emote gets the
  desk-slam sound). Turn off if you'd rather add sounds yourself.

**Export**
- **Export .zip** — builds the full character folder (with `char.ini` *and*
  auto-generated buttons) and downloads/saves a `.zip`.
- **Export char.ini** — just the text file.

**Validation card** — shows errors/warnings (e.g. "No sprite file found for X")
with a plain-language fix for each. Green = all good. 🎉

---

## 5. Emotes — edit your character

**Left panel (the emote list)**
- **Drag** a row to reorder emotes (this also renumbers them).
- **+** adds a new blank emote.
- **↶ / ↷** undo / redo any change.
- The **trash** icon on a row deletes that emote.
- **Click** a row to select and edit it.

**Right panel (preview + settings)**
- The big preview shows the selected sprite. **Scroll / pinch to zoom**, **drag
  to pan** — handy for lining things up.
- Settings you can change:
  - **Name** — the label on the button / in the dropdown.
  - **Sprite** — the base file name (the `(a)`/`(b)` part).
  - **Preanim** — preanimation name, or `-` for none.
  - **Modifier** — *Idle* (no preanim), *Play preanim + sound*, *Zoom* (speed
    lines, hides desk), or *Zoom + preanim*.
  - **Desk** — force the desk/stand shown or hidden, with preanim variations.
  - **Sound (SoundN)** — the sound effect name.
  - **Delay ticks** — wait before the sound plays (1 tick = 60 ms).
  - **Loop sound** — repeat the sound.

Edits save into your project automatically; use **Undo/Redo** freely.

---

## 6. Colour Lab — recolour sprites

Great for tinting, themed variants, and OCs (recolour Mario to pink without
flattening his shading).

1. Pick an emote in the **Emotes** tab first (the Lab recolours the selected
   sprite).
2. In **Colour Lab**, drag the sliders — the preview updates live:
   - **Hue** (shift colours), **Saturation**, **Brightness**, **Contrast**.
3. Tap **Preset** chips (there are hundreds — "Make it Pink", "Vaporwave",
   "CRT", "Sepia", "Teal & Orange", …) and **Gradient map** chips (Fire, Ice,
   Rainbow, …). They **blend (stack)** on top of each other and your sliders, so
   you can combine several — each one you add shows as a chip under "Blended"
   with an ✕ to remove it.
4. **Custom colour** — type a **hex** code right in the panel (e.g. `FF5577`), or
   tap the wheel icon to open the colour **wheel** (hue wheel + sliders + its own
   editable hex bar + HEX/RGB/HSV readouts). Then blend that exact colour in as
   **Recolour to** (re-hue preserving shading), **Tint**, **Solid fill**, or
   **Gradient** — each adds to the blend stack like a preset.
5. Apply it:
   - **Apply** — bakes the look into **this** sprite.
   - **All sprites** — applies it to **every** sprite (great for a uniform theme).
6. **Reset** clears the sliders and the blend stack.

> "Make it `<colour>`" / "Recolour to" keep the original light/shadow, so
> recolours look natural.

For recolouring **just part** of a sprite (only the clothes/hair), see
[COLOR_OPS.md → region editing](COLOR_OPS.md#region--outfit-editing).

---

## 7. Animate — make sprites move

Anyone can animate here — pick an effect, watch it loop, save. AO sprites are
just animated images, so the result works natively.

1. Select an emote (Emotes tab).
2. In **Animate**, either:
   - click a **Preset** ("Idle Breathe", "Happy Bounce", "Angry Shake",
     "Magical", "Spin", "Heartbeat", "Hologram", "Glitch", …), **or**
   - click chips under **Add an effect** to stack your own (e.g. `bob` + `glow` +
     `rainbow`). Stacked effects combine.
3. Tune it:
   - **Frames** — smoothness (more = smoother, bigger file).
   - **Speed** — playback fps.
   - **Easing** — the *feel* (linear, bouncy, springy `elastic`, snappy
     `easeOutBack`, …).
   - Each added effect has its own **strength** slider (and an ✕ to remove it).
4. Save:
   - **Save (b) talk (WebP)** — saves it as the **talking** animation.
   - the **moon icon** saves it as the **(a) idle** animation.
   - It's added to your project *and* downloaded. WebP is the default; it
     automatically falls back to APNG if your platform can't make WebP.

**Move just a hand/limb, lip-sync, or hand-author keyframes** are supported too —
see [ANIMATION.md](ANIMATION.md) (regions, `LipSync`, the keyframe `Timeline`).

---

## 8. Buttons — emote icons

Buttons are made **automatically** when you export (each sprite is trimmed,
cropped to a centred square, and scaled). This tab lets you check them.

1. Select an emote.
2. See its auto button in the preview box.
3. Drag **Button size** (default **128 px**; 40 px is AO's bare minimum, up to 256).
4. **Export character (.zip) with auto buttons** writes them all into
   `emotions/`.

> Want a custom icon? Drop your own `buttonN_off.png` into the character's
> `emotions/` folder afterwards and it takes priority. The advanced
> background/foreground/mask compositor exists in the engine (see the roadmap).

---

## 9. Edit — crop, trim & remove background

Open the **Edit** tab (pick an emote first).

- **Auto-trim transparent margins** — tightens the sprite to its visible pixels.
- **Remove background** — flood-fills from the four corners and makes a flat/near-
  flat background transparent. Use the **BG tolerance** slider if it removes too
  little or too much.
- **Crop** — drag the **Left / Top / Right / Bottom** sliders to trim edges.
- Watch the live preview, then **Apply** (this emote) or **All sprites**.

Crop and auto-trim apply the **same box to every frame and to an emote's
`(a)`/`(b)`/`(c)` sprites**, so animations and idle/talk stay perfectly aligned.
(The result is baked into the sprite files — use Export afterwards.)

---

## 10. Mixer — snip & combine sprites

The "frankensprite" tool: put one character's head on another's body, etc.

1. **Body (base)** — choose the sprite that forms the bottom.
2. **Snip from (overlay)** — choose the sprite you'll take a piece from.
3. Toggle **Ellipse snip** on for heads (off = rectangle).
4. Drag the **Snip region** sliders (X / Y / Width / Height) to frame the part
   you want.
5. Drag the **Placement** sliders (Pos X / Y, Scale, Rotate, Opacity) to drop it
   onto the body.
6. Type a **New sprite name** and click **Save as new emote**.

Tip: recolour the snipped piece first (Colour Lab) so it matches the body, then
animate the result in the Animate tab — a mixed sprite is just a normal sprite.

---

## 11. Bulk — do everything at once

**Recolour ALL sprites**
1. Build a look in the **Colour Lab** (sliders/preset) — it becomes the "live
   pipeline".
2. In **Bulk**, the Recolour card shows how many ops are in it.
3. Click **Recolour ALL sprites**.

**Bulk rename emotes**
- **Find / Replace** (e.g. find `_` replace with a space), add a **Prefix** or
  **Suffix**, **Number** them with a template (`{n}` = number, `{name}` =
  current name, e.g. `Emote {n}`), and pick a **Case** (Title/lower/UPPER).
- Tick **Also rename the sprite files** to rename the underlying `(a)`/`(b)`/
  static files too (root sprites), not just the labels.
- **Apply rename to ALL emotes**. (Undo is available back in the Emotes tab.)

**Convert format**
1. Pick a **format** (default **WebP**; also PNG/APNG, GIF).
2. For **WebP**: choose **Lossless** or set a **Quality**. A note tells you if
   the WebP encoder is available on your platform (on the website it always is).
3. **Delete originals** (optional) avoids AO picking the old file by extension
   priority.
4. **Convert ALL sprites** — animation frames are preserved for PNG/APNG/GIF (and
   animated WebP on native).

---

## 12. Plugins — add more content

Packs are small JSON files that add presets, palettes, gradients, animations and
emote-name sets. They need no install and work on the website too.

- **Import pack (.json)** — pick a pack file; its content immediately appears in
  the Colour Lab / Animate tabs.
- Installed packs are listed with a **trash** icon to remove them.
- A sample pack ships at `assets/presets/example_pack.json` — copy it, edit it,
  re-import. The format is documented in [PLUGINS.md](PLUGINS.md).

---

## 13. Common workflows

**Make a character from a folder of images**
Home → Import → (check the Validation card) → Export .zip. That's the whole job.

**Make a recoloured OC variant**
Import the base → Colour Lab → "Make it `<colour>`" or sliders → **All sprites**
→ change the **Character name** on Home → Export .zip.

**Add a talking animation to a static sprite**
Select the emote → Animate → preset like "Idle Breathe" (save as **(a)**) and/or
a talk effect (save as **(b)**) → Export.

**Convert an old character to WebP**
Import the folder → Bulk → format **WebP** → optionally **Delete originals** →
**Convert ALL** → Export.

**Frankensprite**
Mixer → pick body + overlay → snip the head (ellipse) → place → Save as new
emote → Export.

---

## 14. Using your character in AO
1. **Export .zip** from Home (or Buttons).
2. Unzip it into your AO install's `base/characters/` folder (so you get
   `base/characters/<YourName>/char.ini`).
3. Launch AO, pick the character. (For webAO, host the files where your server
   expects them.)

Purrfect's output matches what the AO2 client and webAO read, including buttons,
sounds, preanimations, and frame effects.

---

## 15. Tips & troubleshooting
- **A tab says "No project yet."** Import sprites on **Home** first.
- **"No sprite file found for X"** in Validation — the emote's **Sprite** name
  doesn't match a file. Fix the name in the Emotes tab, or add the file.
- **Recolour preview looks slightly soft.** The live preview uses a smaller copy
  for speed; **Apply** bakes at full resolution.
- **WebP export unavailable on desktop.** Install libwebp (and libwebpmux for
  animation) — see [PLUGINS.md](PLUGINS.md#native-libwebp) — or just use the
  website build, where WebP works out of the box. It falls back to APNG
  automatically either way.
- More answers: [FAQ.md](FAQ.md).
