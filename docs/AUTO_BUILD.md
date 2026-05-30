# Auto-build: folder → finished character

The headline feature. **Import a whole folder** (Home → Import folder — a native
directory picker on desktop/mobile, a `webkitdirectory` upload on the web) or
pick individual images, and Pinsel produces a working character with zero
configuration — then lets you tweak any of its decisions. Sub-folder structure
is preserved, and an existing `char.ini` in the folder is loaded losslessly
instead of rebuilt.

## The pipeline

```
files ─► SpriteScanner.fromPaths ─► ScanResult
      ─► CharacterBuilder.build   ─► Character
      ─► Organizer.organize       ─► folders + char.ini + auto buttons ─► .zip
```

### 1. Scanning (`SpriteScanner`)
Each image is classified by its name:
- `(a)foo` → **idle** of `foo`; `(b)foo` → **talk**; `(c)foo` → **post**.
- `foo` (no prefix) → **static** sprite `foo`.
- Sub-folders: `(a)/def/foo` → idle of `/def/foo`; a file at `extra/foo.png` →
  static `/extra/foo`.
- Files under `anim/` are collected as **preanimation candidates**, not emotes.
- Character chrome (`char_icon`, `objection`, `holdit`, `takethat`,
  speedlines, anything in `emotions/`, `_old_emotions/`, `custom_objections/`)
  is **ignored**.
- When several formats share a name, the highest-priority extension wins
  (`webp` > `apng` > `gif` > `png`).

Files that resolve to the same logical sprite are grouped (`SpriteGroup`), so
`(a)happy`, `(b)happy`, and `happy` become one emote.

### 2. Building (`CharacterBuilder`)
Each group becomes an emote:
- **Name** — a friendly Title Case of the base (`upset_look_left` → "Upset Look
  Left").
- **Modifier** — idle pair → `Idle (0)`. If a bare same-named file *also* exists
  alongside an `(a)`/`(b)` pair, the bare one is treated as a **preanimation**
  (`treatBareAsPreanim`, on by default) and the modifier becomes "play preanim".
- **Desk** — defaults to "show".
- **Sounds** — optional name-based guesses (e.g. "slam" → `sfx-deskslam` at 4
  ticks). Toggle with `guessSounds`.
- Emotes named `normal`/`neutral`/`idle`/`default`/`1` float to the front.

If the folder already contains a `char.ini`, it is parsed instead of rebuilt, so
you can re-open and keep editing existing characters losslessly.

All of this is configurable via `BuildConfig` (name, side, blips, chat, scaling,
default deskmod, the two heuristics, and the preferred-first list).

### 3. Organising (`Organizer`)
- Copies every source file into `characters/<name>/`, preserving structure.
- Writes `char.ini`.
- **Auto-generates buttons**: for each emote it takes the representative sprite's
  first frame, trims transparent margins, crops a centred square, and scales it
  to size → `emotions/buttonN_off.png`. Existing buttons are kept unless you ask
  to overwrite.
- Exports the result as a `.zip` you drop straight into AO.

## Overriding decisions
Everything the auto-builder does is editable afterwards in the **Emotes** screen
(rename, reorder via drag, change sprite/preanim/modifier/desk/sound, add/delete),
and the **Button Studio** lets you drop in custom buttons. Re-run the builder any
time with **Regenerate** (it re-reads the sprites with your current options).
