# Keyboard shortcuts

Global shortcuts work from anywhere in the app. **Control** and **⌘ (Command)**
are both bound, so the same keys work on Windows/Linux and macOS. Press **F1**
in-app to pop up this list, and find the same actions as buttons on the **top
toolbar** (undo / redo / import / export).

| Shortcut | Action |
|----------|--------|
| `Ctrl/⌘ + Z` | Undo |
| `Ctrl/⌘ + Y` *or* `Ctrl/⌘ + Shift + Z` | Redo |
| `Ctrl/⌘ + O` | Import a folder of sprites |
| `Ctrl/⌘ + S` | Export the character as a `.zip` |
| `Ctrl/⌘ + E` | Export just `char.ini` |
| `Ctrl/⌘ + N` | Add a new emote |
| `Ctrl/⌘ + ↑` / `Ctrl/⌘ + ↓` | Select the previous / next emote |
| `Ctrl/⌘ + 1 … 9` | Jump to a screen (1 = Home, 2 = Character, … 9 = Bulk) |
| `F1` | Show the shortcuts cheat-sheet |

> Inside a text field, `Ctrl+Z` is handled by the field (text undo). Click
> anywhere outside the field first to use the global undo/redo.

## Screen numbers (`Ctrl/⌘ + 1…9`)

1. Home · 2. Character · 3. Emotes · 4. Colour Lab · 5. Animate · 6. Buttons ·
7. Edit · 8. Mixer · 9. Bulk

> The 10th screen, **Plugins**, has no number shortcut (there are only nine
> digits) — click it in the rail.

## Undo / redo scope

Undo/redo cover **character/emote model** edits (names, sprite fields, order,
add/delete, sound, etc.). Baked **pixel** changes (recolour / crop / animation
saves) write straight to the sprite files and aren't on the undo stack — re-run
the tool or re-import to change them.

## Adding your own

Shortcuts live in `lib/src/app.dart` (`_HomeShellState._bindings`), a
`CallbackShortcuts` map of `SingleActivator` → callback. Add a `bind(key, cb)`
line (it registers both the Control and ⌘ variants) and document it here.
