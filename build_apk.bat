@echo off
chcp 65001 >nul
title VK Z - Build APK

echo ============================================
echo       VK Z - Android Music Player
echo       Building APK...
echo ============================================
echo.

:: Use Android Studio's built-in JDK
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set ANDROID_HOME=C:\Users\Werhes\AppData\Local\Android\Sdk

echo [1/4] Checking Java...
if exist "%JAVA_HOME%\bin\java.exe" (
    echo   Java found: %JAVA_HOME%
) else (
    echo   ERROR: Java not found at %JAVA_HOME%
    echo   Please install Android Studio or set JAVA_HOME manually.
    pause
    exit /b 1
)

echo [2/4] Checking Android SDK...
if exist "%ANDROID_HOME%\platforms" (
    echo   SDK found: %ANDROID_HOME%
) else (
    echo   ERROR: Android SDK not found at %ANDROID_HOME%
    pause
    exit /b 1
)

echo [3/4] Cleaning old builds...
if exist "app\build\outputs\apk" (
    rmdir /s /q "app\build\outputs\apk" 2>nul
    echo   Cleaned.
) else (
    echo   Nothing to clean.
)

echo [4/4] Building APK (this may take a few minutes)...
echo.
echo   Building debug APK...
echo.

call "%JAVA_HOME%\bin\java" -version 2>&1 | findstr /i "version" >nul
if %ERRORLEVEL% neq 0 (
    echo   ERROR: Java is not working properly.
    pause
    exit /b 1
)

:: Run Gradle build
call gradlew.bat assembleDebug --no-daemon

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================
    echo       BUILD SUCCESSFUL!
    echo ============================================
    echo.
    echo   APK location:
    echo   app\build\outputs\apk\debug\app-debug.apk
    echo.
    echo   Install on device:
    echo   adb install app\build\outputs\apk\debug\app-debug.apk
    echo.
) else (
    echo.
    echo ============================================
    echo       BUILD FAILED!
    echo ============================================
    echo.
    echo   Check the error messages above.
    echo   Common issues:
    echo     1. Missing dependencies - check internet connection
    echo     2. SDK version mismatch - check local.properties
    echo     3. Replace YOUR_VK_APP_ID in LoginActivity.kt
    echo.
)

pause