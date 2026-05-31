# Build every locally-available Pinsel target (Windows).
#   Usage:  powershell -ExecutionPolicy Bypass -File scripts\build_all.ps1
$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "Flutter SDK not found on PATH. Install from https://docs.flutter.dev/get-started/install"
}

Write-Host "==> Bootstrapping platform folders..." -ForegroundColor Cyan
flutter create .
flutter pub get

Write-Host "==> Running tests..." -ForegroundColor Cyan
flutter test

Write-Host "==> Building Windows..." -ForegroundColor Cyan
flutter build windows --release

# Bundle libwebp + libwebpmux DLLs next to the .exe so WebP — including ANIMATED
# WebP (needs libwebpmux) — works instead of silently falling back to APNG. This
# mirrors the CI step; without it a locally-built app exports APNG. Best-effort:
# needs vcpkg (VCPKG_ROOT / VCPKG_INSTALLATION_ROOT / on PATH). Skips with a
# warning if vcpkg isn't available — the app still runs (just APNG animations).
Write-Host "==> Bundling libwebp (+mux for animated WebP)..." -ForegroundColor Cyan
try {
  $dst = "build\windows\x64\runner\Release"
  if (-not (Test-Path $dst)) { throw "Release build folder not found ($dst)." }

  $vcpkgExe = $null
  foreach ($root in @($env:VCPKG_ROOT, $env:VCPKG_INSTALLATION_ROOT)) {
    if ($root -and (Test-Path (Join-Path $root 'vcpkg.exe'))) {
      $vcpkgExe = Join-Path $root 'vcpkg.exe'; break
    }
  }
  if (-not $vcpkgExe) {
    $cmd = Get-Command vcpkg -ErrorAction SilentlyContinue
    if ($cmd) { $vcpkgExe = $cmd.Source }
  }
  if (-not $vcpkgExe) { throw "vcpkg not found (set VCPKG_ROOT or add vcpkg to PATH)." }

  $vcRoot = Split-Path $vcpkgExe
  & $vcpkgExe install libwebp:x64-windows | Out-Host
  $bin = Join-Path $vcRoot 'installed\x64-windows\bin'
  if (-not (Test-Path $bin)) { throw "vcpkg libwebp bin dir not found ($bin)." }

  Get-ChildItem $bin -Filter *.dll |
    Where-Object { $_.Name -match 'webp|sharpyuv' } |
    ForEach-Object { Copy-Item $_.FullName $dst -Force }

  $names = (Get-ChildItem $dst -Filter *.dll | Select-Object -ExpandProperty Name)
  Write-Host ("Bundled DLLs: " + ($names -join ', '))
  if ($names -match 'webpmux') {
    Write-Host "libwebpmux bundled - animated WebP available." -ForegroundColor Green
  } else {
    Write-Warning "libwebpmux DLL not found - animated WebP may fall back to APNG."
  }
} catch {
  Write-Warning "Skipped libwebp bundling: $($_.Exception.Message)"
  Write-Warning "Animations will export APNG until libwebp + libwebpmux DLLs sit next to the .exe."
}

Write-Host "==> Building Web..." -ForegroundColor Cyan
flutter build web --release

# Android requires the Android SDK; build if available.
try {
  Write-Host "==> Building Android APK..." -ForegroundColor Cyan
  flutter build apk --release
} catch {
  Write-Warning "Skipped Android build (Android SDK not configured)."
}

Write-Host "`nDone. Outputs:" -ForegroundColor Green
Write-Host "  Windows : build\windows\x64\runner\Release\"
Write-Host "  Web     : build\web\"
Write-Host "  Android : build\app\outputs\flutter-apk\app-release.apk (if built)"
