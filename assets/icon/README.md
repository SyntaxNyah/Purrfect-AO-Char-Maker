# App icon

`app_icon.png` is the source the launcher icons are generated from (Windows,
macOS, Linux, Android, iOS, web).

**The file here is a placeholder** (a simple brush/wordmark). Replace it with the
real **Pinsel mascot — a cute anime girl** when you have the art:

1. Export your artwork as **1024×1024 PNG** (square, full-bleed; a small safe
   margin helps because some platforms round/mask the corners).
2. Save it over `assets/icon/app_icon.png` (keep the name).
3. Regenerate every platform icon:
   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```
   (Run `flutter create .` first if the platform folders don't exist yet.)

Config lives in `pubspec.yaml` under `flutter_launcher_icons:` — tweak the
background/theme colours there if you want.

> Tip: keep a transparent-background master too; iOS flattens alpha (we set
> `remove_alpha_ios` + a background colour for it).
