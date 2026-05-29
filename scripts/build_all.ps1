# Build every locally-available Purrfect target (Windows).
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
