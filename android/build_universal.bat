@echo off
chcp 65001 >nul
title VK-Z Android Universal APK Builder

:: Переходим в папку со скриптом
cd /d "%~dp0"

echo ============================================
echo    VK-Z - Сборка Universal APK
echo ============================================
echo.

:: Проверка наличия Java
where java >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ОШИБКА] Java не найдена! Установите JDK 17+.
    echo.
    pause
    exit /b 1
)

:: Проверка версии Java
for /f "tokens=3" %%g in ('java -version 2^>^&1 ^| findstr /i "version"') do (
    set JAVA_VERSION=%%g
)
echo [OK] Java: %JAVA_VERSION%

:: Проверка наличия ANDROID_HOME
if "%ANDROID_HOME%"=="" (
    if exist "%LOCALAPPDATA%\Android\Sdk" (
        set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
    ) else (
        echo [ОШИБКА] ANDROID_HOME не задан!
        echo Укажите путь к Android SDK в переменной окружения ANDROID_HOME
        echo.
        pause
        exit /b 1
    )
)
echo [OK] Android SDK: %ANDROID_HOME%

:: Создание local.properties если нет
if not exist "local.properties" (
    echo sdk.dir=%ANDROID_HOME:\=\\> "local.properties"
    echo [OK] Создан local.properties
)

echo.
echo [1/3] Очистка предыдущей сборки...
call gradlew clean --no-daemon 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ОШИБКА] Очистка не удалась!
    pause
    exit /b 1
)
echo [OK] Очистка завершена

echo.
echo [2/3] Сборка Universal APK (Debug)...
call gradlew assembleDebug --no-daemon 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ОШИБКА] Сборка не удалась! Проверьте вывод выше.
    pause
    exit /b 1
)
echo [OK] Сборка завершена

:: Поиск APK
set APK_FILE=
for /r "app\build\outputs\apk" %%f in (*universal*.apk) do set APK_FILE=%%f
if "%APK_FILE%"=="" (
    for /r "app\build\outputs\apk" %%f in (*.apk) do set APK_FILE=%%f
)

echo.
echo [3/3] Копирование APK...
if not "%APK_FILE%"=="" (
    copy /Y "%APK_FILE%" "VK-Z-Universal.apk" >nul
    echo [OK] Universal APK создан: VK-Z-Universal.apk
    for %%f in ("%APK_FILE%") do echo [INFO] Размер: %%~zf байт
) else (
    echo [ПРЕДУПРЕЖДЕНИЕ] APK не найден в ожидаемой папке
)

echo.
echo ============================================
echo    Сборка завершена успешно!
echo ============================================
echo.
pause