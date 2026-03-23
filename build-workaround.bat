@echo off
echo Building Social Memories APK with workaround...
echo.

echo Step 1: Clean build...
flutter clean

echo Step 2: Get dependencies...
flutter pub get

echo Step 3: Try debug build first...
flutter build apk --debug

if %ERRORLEVEL% EQU 0 (
    echo Debug build successful!
    echo APK location: build\app\outputs\flutter-apk\app-debug.apk
) else (
    echo Debug build failed, trying release with different flags...
    flutter build apk --release --no-shrink --verbose
    
    if %ERRORLEVEL% EQU 0 (
        echo Release build successful!
        echo APK location: build\app\outputs\flutter-apk\app-release.apk
    ) else (
        echo Both builds failed. Try using GitHub Actions or Android Studio.
    )
)

echo.
echo Build process completed.
echo Check build\app\outputs\flutter-apk\ folder for APK files.
echo.
pause
