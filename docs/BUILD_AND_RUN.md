# Build & Run

Purrfect is a Flutter app, so one codebase targets Windows, Linux, macOS,
Android, iOS and the web.

## Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.22 or newer**
  (Dart 3.4+). Run `flutter doctor` and fix anything it flags for your target.

## First-time bootstrap
The platform project folders (`android/`, `ios/`, `linux/`, `macos/`,
`windows/`, `web/`) are **not** committed — generate them once:

```bash
cd Purrfect-AO-Char-Maker
flutter create .          # generates the platform folders, keeps lib/ etc.
flutter pub get
```

## Run (debug)
```bash
flutter run -d windows     # Windows desktop
flutter run -d linux       # Linux desktop
flutter run -d macos       # macOS desktop
flutter run -d chrome      # Web (in a browser)
flutter run                # pick a connected Android/iOS device
flutter devices            # list what's available
```

## Run the tests
```bash
flutter test
```
The engine is covered by pure-Dart tests (INI, character round-trip, scanner,
colour ops, animation).

## Build releases

| Target | Command | Output |
|--------|---------|--------|
| Windows | `flutter build windows --release` | `build/windows/x64/runner/Release/` |
| Linux | `flutter build linux --release` | `build/linux/x64/release/bundle/` |
| macOS | `flutter build macos --release` | `build/macos/Build/Products/Release/` |
| Android | `flutter build apk --release` (or `appbundle`) | `build/app/outputs/` |
| iOS | `flutter build ios --release` | Xcode archive/run |
| Web | `flutter build web --release` | `build/web/` |

## The website
```bash
flutter build web --release
```
Serve `build/web/` from any static host (GitHub Pages, Netlify, Cloudflare
Pages, itch.io, …). The web build:
- imports images via the file picker (no folder access needed),
- does **all** processing in-browser,
- encodes **WebP (lossy + near-lossless)** using the browser's own codec,
- exports a `.zip` via a normal browser download — perfect for sharing.

> CanvasKit vs HTML renderer: the default is fine. CanvasKit gives the most
> consistent image rendering; build with `--web-renderer canvaskit` if you want
> to force it.

## Native WebP (desktop/mobile)
WebP **encoding** on native uses `libwebp` via FFI (decoding always works). If
the library isn't found, WebP export reports it and other formats still work.
See [PLUGINS.md](PLUGINS.md#native-libwebp) to install/bundle it.

## Mobile file access
iOS and Android sandbox the filesystem. Purrfect imports images through the
system picker and exports a `.zip`, which works within the sandbox everywhere.
In-place editing of an existing AO `characters/` folder on mobile (via the
Storage Access Framework) is on the roadmap.

## Troubleshooting
- **`flutter create .` overwrote something?** It only creates missing platform
  folders and standard config; your `lib/`, `test/`, `assets/`, and docs are
  left alone.
- **Web build fails on `dart:io`/`dart:html`?** Make sure you import
  `platform/workspace_factory.dart` (not `io_workspace.dart`/`web_workspace.dart`
  directly). The provided code already does this.
- **`flutter pub get` resolver errors?** Match the SDK constraint in
  `pubspec.yaml` (`>=3.4.0 <4.0.0`) or bump Flutter.
