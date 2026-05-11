@echo off
setlocal enabledelayedexpansion

echo Installing dependencies...
flutter pub get

echo Building Android APK...
flutter build apk --release

echo Building Web app...
flutter build web --release

echo To build iOS, run the following on a Mac:
   flutter build ios --release --no-codesign

echo Build complete.
