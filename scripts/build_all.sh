#!/usr/bin/env bash
# Build every locally-available Purrfect target (Linux/macOS).
#   Usage:  bash scripts/build_all.sh
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found on PATH. Install: https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

echo "==> Bootstrapping platform folders..."
flutter create .
flutter pub get

echo "==> Running tests..."
flutter test

echo "==> Building Web..."
flutter build web --release

UNAME="$(uname -s)"
if [ "$UNAME" = "Darwin" ]; then
  echo "==> Building macOS..."
  flutter build macos --release
else
  echo "==> Building Linux..."
  flutter build linux --release
fi

if flutter build apk --release; then
  echo "Android APK built."
else
  echo "Skipped Android build (Android SDK not configured)."
fi

echo
echo "Done. See build/ for outputs."
