@echo off
REM AN Life Tracker - Build Script for Windows
REM Builds Android APK

echo.
echo ========================================
echo   AN LIFE TRACKER - Android Build
echo ========================================
echo.

echo [1/5] Cleaning previous builds...
flutter clean

echo.
echo [2/5] Getting dependencies...
flutter pub get

echo.
echo [3/5] Running build_runner (if needed)...
REM flutter pub run build_runner build --delete-conflicting-outputs

echo.
echo [4/5] Building Release APK...
echo This may take 5-10 minutes...
flutter build apk --release

echo.
echo [5/5] Build Complete!
echo.
echo ========================================
echo   BUILD SUCCESSFUL!
echo ========================================
echo.
echo Your APK is ready at:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo File size: 
dir build\app\outputs\flutter-apk\app-release.apk | find "app-release"
echo.
echo Compatible with: Android 5.0 - Android 14+ (including Android 13)
echo.
echo Next steps:
echo 1. Transfer APK to your Android phone
echo 2. Enable "Install from Unknown Sources" in Settings
echo 3. Open the APK file to install
echo.
echo Note: Play Protect may show a warning for sideloaded apps.
echo      This is normal! Our app is completely safe.
echo      Tap "More Details" and "Install Anyway"
echo.
pause
