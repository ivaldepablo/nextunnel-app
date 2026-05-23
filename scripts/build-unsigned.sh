#!/usr/bin/env bash
# Build unsigned release binaries for all desktop platforms + Android APK.
# Used by the GitHub Actions release workflow (.github/workflows/release.yml)
# to produce nightly + tagged builds without paid Apple/Microsoft certs.
#
# Output layout (relative to repo root):
#   dist/NexTunnel-<version>-windows-x64.zip   (contains .exe + DLLs)
#   dist/NexTunnel-<version>-macos-arm64.zip   (contains .app bundle)
#   dist/NexTunnel-<version>-macos-amd64.zip   (contains .app bundle)
#   dist/NexTunnel-<version>-linux-x64.tar.gz  (contains binary + assets)
#   dist/NexTunnel-<version>-android.apk       (universal APK)
#   dist/checksums.txt                         (SHA-256 sums for /api/client/version)
#
# Users will see a Gatekeeper / SmartScreen warning on first launch; the
# /downloads page documents the right-click → Open / "Run anyway" steps.

set -euo pipefail

VERSION="${1:-$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)}"
DIST="dist"
mkdir -p "$DIST"

echo "==> Building NexTunnel $VERSION"

# Ensure deps + codegen
flutter pub get
dart run build_runner build --delete-conflicting-outputs

case "$(uname -s)" in
  Darwin)
    echo "==> macOS (arm64)"
    flutter build macos --release
    pushd build/macos/Build/Products/Release >/dev/null
    zip -rq "../../../../../$DIST/NexTunnel-$VERSION-macos-arm64.zip" "NexTunnel.app"
    popd >/dev/null
    ;;
  Linux)
    echo "==> Linux (x64)"
    flutter build linux --release
    pushd build/linux/x64/release/bundle >/dev/null
    tar -czf "../../../../../$DIST/NexTunnel-$VERSION-linux-x64.tar.gz" .
    popd >/dev/null

    echo "==> Android APK"
    flutter build apk --release
    cp build/app/outputs/flutter-apk/app-release.apk "$DIST/NexTunnel-$VERSION-android.apk"
    ;;
  MINGW*|CYGWIN*|MSYS*)
    echo "==> Windows (x64)"
    flutter build windows --release
    pushd build/windows/x64/runner/Release >/dev/null
    7z a -tzip "../../../../../$DIST/NexTunnel-$VERSION-windows-x64.zip" "*"
    popd >/dev/null
    ;;
esac

# Generate SHA-256 checksums for the version manifest
echo "==> Computing checksums"
pushd "$DIST" >/dev/null
shasum -a 256 NexTunnel-*.* > checksums.txt
cat checksums.txt
popd >/dev/null

echo "==> Done. Artifacts in $DIST/"
