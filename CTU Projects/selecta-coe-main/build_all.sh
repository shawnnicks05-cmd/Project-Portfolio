#!/bin/bash
set -e

echo "Installing dependencies..."
flutter pub get

echo "Building Android APK..."
flutter build apk --release

echo "Building iOS app (requires macOS and Xcode)..."
flutter build ios --release --no-codesign

echo "Building Web app..."
flutter build web --release

echo "Build complete:"
echo "  - Android APK: build/app/outputs/flutter-apk/app-release.apk"
echo "  - iOS app: build/ios/iphoneos/Runner.app"
echo "  - Web site: build/web"
