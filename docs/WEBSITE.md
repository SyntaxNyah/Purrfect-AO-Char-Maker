# Hosting Pinsel as a website

Pinsel compiles to a normal static web app (HTML/JS/Wasm + assets). Build it
once, then drop the output on any static host. Everything runs **client-side** —
no server, no backend, no uploads — so it's cheap (or free) to host and easy to
share.

## 1. Build

```bash
flutter create .            # first time only (generates web/ etc.)
flutter pub get
flutter build web --release
```

Output lands in **`build/web/`**. That folder *is* the website.

> **Hosting under a sub-path?** (e.g. `you.github.io/Pinsel-AO-Char-Maker/`)
> pass a matching base href:
> ```bash
> flutter build web --release --base-href /Pinsel-AO-Char-Maker/
> ```
> Hosting at a domain root (`example.com/`)? Use `--base-href /` (the default).

## 2. Pick a host

### Option A — GitHub Pages (automated, recommended)
This repo already ships a CI workflow (`.github/workflows/build.yml`) that builds
the web app and **publishes it to GitHub Pages on every version tag**:

```bash
git tag v0.1.0
git push origin v0.1.0
```
Then in your repo: **Settings → Pages → Source: "GitHub Actions"** (or the
`gh-pages` branch, which the workflow populates). Your site appears at
`https://<user>.github.io/Pinsel-AO-Char-Maker/`.

To do it by hand instead:
```bash
flutter build web --release --base-href /Pinsel-AO-Char-Maker/
# commit the contents of build/web to a `gh-pages` branch, or use:
npx gh-pages -d build/web
```

### Option B — Netlify
- **Drag & drop:** build locally, then drag `build/web/` onto
  https://app.netlify.com/drop. Done.
- **Connected repo:** set Build command `flutter build web --release` and
  Publish directory `build/web`. (Add Flutter to the build image via a
  `netlify.toml` that installs it, or use a prebuilt step.)

### Option C — Cloudflare Pages
Create a Pages project, set the build output directory to `build/web`. Use a
custom build image/step that has Flutter, or upload a pre-built `build/web`
with Direct Upload.

### Option D — itch.io
Zip the **contents** of `build/web` (so `index.html` is at the zip root), create
a new project, set it to **HTML**, upload the zip, and tick *"This file will be
played in the browser"*. Set the viewport size generously (e.g. 1280×800).

### Option E — Self-host (nginx/Apache/any static server)
Copy `build/web/` to your web root. Minimal nginx:
```nginx
server {
  listen 80;
  root /var/www/pinsel;       # contents of build/web
  index index.html;
  location / { try_files $uri $uri/ /index.html; }
}
```

## 3. Optional tuning

- **Renderer.** The default is fine. For the most consistent image rendering you
  can force CanvasKit: `flutter build web --release --web-renderer canvaskit`.
- **Faster CanvasKit (SharedArrayBuffer).** Serve with these headers if your host
  allows it:
  ```
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  ```
- **Cache busting.** Flutter fingerprints assets; just make sure your host
  doesn't cache `index.html`/`flutter_service_worker.js` too aggressively.
- **Custom domain.** Point a CNAME at your host (GitHub Pages: add a `CNAME`
  file or set it in Settings → Pages).

## 4. What users get on the web build
- Import sprite **files** *or a whole **folder*** (the web build uses a
  `webkitdirectory` folder upload, preserving sub-folder structure).
- All scanning, auto-`char.ini`, recolour, animation, mixing, cropping,
  background removal, and button + `char_icon` generation happen in the browser.
- **WebP export works out of the box** (browser-native encoder). *Animated* WebP
  is the one thing the browser can't encode, so animations export as APNG on web.
- Export a ready-to-use character **`.zip`** via a normal download.
- **Plugin packs** can be imported (JSON upload) — they work on web too.

That makes the website a perfect way to *share* the tool: send someone a link
and they can build an AO character with nothing installed.
