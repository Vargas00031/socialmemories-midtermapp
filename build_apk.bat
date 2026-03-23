@echo off
echo Building APK for Social Memories App...
echo.

echo Step 1: Cleaning previous builds...
flutter clean

echo Step 2: Getting dependencies...
flutter pub get

echo Step 3: Building APK...
flutter build apk --release --no-shrink

echo.
echo Build completed!
echo.
echo APK Location: build\app\outputs\flutter-apk\app-release.apk
echo.
echo You can now upload this APK to GitHub!
echo.
pause
