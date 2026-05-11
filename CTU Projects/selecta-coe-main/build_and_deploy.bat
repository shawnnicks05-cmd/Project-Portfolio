@echo off
echo Building SELECTA-COE for web deployment...

REM Clean previous builds
if exist build\web (
    echo Cleaning previous web build...
    rmdir /s /q build\web
)

REM Build for web
echo Building Flutter web app...
flutter build web

if %ERRORLEVEL% EQU 0 (
    echo ✅ Web build successful!
    echo 📁 Build files are in: build\web\
    echo.
    echo 🚀 Deployment options:
    echo 1. GitHub Pages: Push to GitHub and enable Pages in repository settings
    echo 2. Firebase Hosting: Run 'firebase deploy' (requires Firebase CLI setup)
    echo 3. Manual: Upload build\web folder to any web host
    echo.
    echo 🌐 To test locally:
    echo    cd build\web
    echo    python -m http.server 8000
    echo    Then open http://localhost:8000
) else (
    echo ❌ Build failed! Check the error messages above.
)

pause
